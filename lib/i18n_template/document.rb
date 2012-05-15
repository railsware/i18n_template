require 'active_support'
require 'active_support/core_ext/string'
require 'action_controller/vendor/html-scanner/html/tokenizer'

require 'i18n_template/document/node'
require 'i18n_template/document/text'
require 'i18n_template/document/tag'
require 'i18n_template/document/fold'
require 'i18n_template/document/phrase'

module I18nTemplate
  ##
  # Fold is part of text that can't be parsed by HTML tokenizer.
  # Block fold breaks phrase and inline fold acts as part of phrase.
  # Before parsing document as HTML we 'fold' incorrect or not interesting content into 'folds'
  # 
  # For example text like:
  #
  #   <% @now = Time.now %>
  #   <% @users.each_with_index do |user, index| %>
  #     <div class="<%= cycle("odd", "even") -%>">
  #       Username: <%= user.name %>
  #     </div>
  #   <% end %>
  #
  # Will be folded to:
  #
  #     ≤0:block≥
  #     ≤1:block≥
  #       <div class="≤2:inline≥">
  #         Username: ≤3:inline≥
  #       </div>
  #     ≤4:block≥
  #
  # Thus we can now parse HTML.
  # During parsing we create tree with Tag nodes for tag token and Text or Fold nodes from text:
  #
  # Tree:
  #
  #     Root (nil)
  #     ├── Fold (≤0:block≥)
  #     ├── Fold (≤1:block≥)
  #     ├── Tag (<div class="≤2:inline≥">)
  #     │    ├── Text (Username: )
  #     │    └── Fold (≤3:inline≥)
  #     ├── Tag (</div)
  #     └── Fold (≤4:block≥)
  #
  # Nodes stack:
  #
  #    [
  #      Root (nil)
  #      Fold (≤0:block≥)
  #      Fold (≤1:block≥)
  #      Tag (<div class="≤2:inline≥">)
  #      Text (Username: )
  #      Fold (≤3:inline≥)
  #      Tag (</div)
  #      Fold (≤4:block≥)
  #    ]
  #
  # Then we traverse tree twice (in postorder and preorder) and mark nodes with next flags:
  #
  # * :ignore - node is not phrase or part of phrase
  # * :phrase - node is pharse or part of phrase
  # * :candidate - node can be phrase but we can't settle it right know.
  #
  #     Root (nil) (i)
  #     ├── Fold (≤0:block≥) (i)
  #     ├── Fold (≤1:block≥) (i)
  #     ├── Tag (<div class="≤2:inline≥">) (i)
  #     │    ├── Text (Username: ) (p)
  #     │    └── Fold (≤3:inline≥) (p)
  #     ├── Tag (</div) (i)
  #     └── Fold (≤4:block≥) (i)
  #
  #    [
  #      Root (nil) (i)
  #      Fold (≤0:block≥) (i)
  #      Fold (≤1:block≥) (i)
  #      Tag (<div class="≤2:inline≥">) (i)
  #      Text (Username: ) (p)
  #      Fold (≤3:inline≥) (p)
  #      Tag (</div) (i)
  #      Fold (≤4:block≥) (i)
  #    ]
  # 
  # In the next step we create we replace sibling nodes marked as phrase with Phrase node
  #
  #    [
  #      Root (nil) (i)
  #      Fold (≤0:block≥) (i)
  #      Fold (≤1:block≥) (i)
  #      Tag (<div class="≤2:inline≥">) (i)
  #      Phrase(
  #        Text (Username: )
  #        Fold (≤3:inline≥)
  #      )
  #      Tag (</div) (i)
  #      Fold (≤4:block≥) (i)
  #    ]
  #
  # Then we invoke #to_eruby on each node in stack:
  #
  #     ≤0:block≥
  #     ≤1:block≥
  #       <div class="≤2:inline≥">
  #         <%- i18n_values = {} -%><%- i18n_values['{1}'] = capture do-%>≤3:inline≥<%- end -%>
  #         <%= I18nTemplate.t("Username: {1}")
  #       </div>
  #     ≤4:block≥
  #
  # Then we internationalize rails helpers in each fold if they found
  #
  # Then we unold all folds:
  #
  #   <% @now = Time.now %>
  #   <% @users.each_with_index do |user, index| %>
  #     <div class="<%= cycle("odd", "even") -%>">
  #       <%- i18n_values = {} -%><%- i18n_values['{1}'] = capture do-%><%= user.name %><%- end -%>
  #       <%= I18nTemplate.t("Username: {1}", i18n_values) %>
  #     </div>
  #   <% end %>
  #
  # Thus we have internationalized template!
  #
  # Translator key is 'Username: {1}',
  # where value of '{1}' is stored in i18n_values hash as output of expression `<%= user.name %>`.
  #
  class Document

    def initialize(source)
      @source = source.dup
      @folds = []
      @nodes = []
      @errors = []
      @helper_keys = []
    end

    attr_reader :source
    attr_reader :folds
    attr_reader :nodes
    attr_reader :errors
    attr_reader :helper_keys

    def process!
      fold_source_data!

      if build_tree!
        process_nodes!
        store_nodes!
      end

      internationalize_folds!

      unfold_source_data!

      errors.empty?
    end

    def phrase_keys
      @nodes.select { |node| node.is_a?(Phrase) }.map(&:phrase)
    end

    def phrases
      @phrases ||= (phrase_keys + helper_keys)
    end

    alias_method :keys, :phrases

    protected

    def fold_source_data!
      FOLD_TYPE_PATTERN_MAPPING.each do |type, pattern|
        source.gsub!(pattern) do |content|
          fold = "#{FOLD_START}#{folds.size}:#{type}#{FOLD_END}"
          folds.push content
          fold
        end
      end
    end

    def build_tree!
      root = Node.new
      root.flag = :ignore

      nodes.push(root)
      open_tag_stack = [ root ]

      tokenizer = ::HTML::Tokenizer.new(@source)

      while token = tokenizer.next
        case token
        when TAG_PATTERN
          open_tag = $1.nil?
          tag_name = $2.downcase
          if open_tag
            node = Tag.new(token, tag_name, nil)

            node.inherit_i18n_attr(open_tag_stack.last)
            open_tag_stack.last.children.push node
            node.parent = open_tag_stack.last
            open_tag_stack.push(node) unless node.self_close?
          else
            node = Tag.new(token, tag_name, :close)

            if open_tag_stack.last == root
              message = "Extra close tag #{node.name.inspect}"
              errors << message
              break
            end

            unless open_tag_stack.last.name == node.name
              message = "Attempt to close #{open_tag_stack.last.name.inspect} with #{node.name.inspect}"
              errors.push(message)
              break
            end
            open_node = open_tag_stack.pop
            node.inherit_i18n_attr(open_node)
            node.pair_tag = open_node
            open_node.pair_tag = node
            open_tag_stack.last.children.push node
            node.parent = open_tag_stack.last
          end

          nodes.push(node)
        else
          build_content_nodes(token).each do |node|
            node.inherit_i18n_attr(open_tag_stack.last)
            open_tag_stack.last.children.push(node)
            node.parent = open_tag_stack.last
            nodes.push(node)
          end
        end
      end

      errors.empty?
    end

    def build_content_nodes(content)
      list = []
      size = content.size
      start_pos = 0

      content.scan(FOLD_PATTERN) do |fold|
        offset = $~.offset(0)
        end_pos = offset[0] - 1

        list << Text.new(content.slice(start_pos.. end_pos)) if start_pos <= end_pos
        list << Fold.new($~[0], $2)
        start_pos = offset[1]
      end

      list << Text.new(content[start_pos .. size]) if start_pos < size
      list
    end

    def process_nodes!
      if I18nTemplate.debug
        puts "\n@@@ INSPECT NODES @@@"
        nodes.each_with_index do |node, index|
          p node
        end
      end

      flag_node!(nodes.first)

      if I18nTemplate.debug
        puts "\n@@@ INSPECT NODES AFTER POSTORDER TREE TRAVERSE @@@"
        nodes.each_with_index do |node, index|
          p node
        end
      end

      flag_canditate_node!(nodes.first)

      if I18nTemplate.debug
        puts "\n@@@ INSPECT NODES AFTER PREORDER TREE TRAVERSE @@@"
        nodes.each_with_index do |node, index|
          p node
        end
      end

      curent_phrase = nil

      nodes.each_with_index do |node, index|
        if node.phrase?
          nodes[index] = nil
          curent_phrase ||= (nodes[index] = Phrase.new)
          curent_phrase.add_node(node)
        else
          curent_phrase = nil
        end
      end

      nodes.each do |node|
        if node.is_a?(Phrase)
          node.build!
        end
      end

      nodes.compact!
    end

    def store_nodes!
      @source = ""
      nodes.each do |node|
        data = node.to_eruby
        next unless data
        @source << data
      end
    end

    def internationalize_folds!
      @folds.each do |fold|
        fold.gsub!(RAILS_HELPER_PATTERN) { |string|
          prefix = "#{$1}#{$2}" 
          key = ($3 || $4).gsub(/"/, '&quot;')
          @helper_keys << key
          "#{prefix}I18nTemplate.t(#{key.inspect})"
        }
      end
    end

    def unfold_source_data!
      @source.gsub!(FOLD_PATTERN) { @folds[$1.to_i] }
    end

    # Traverse tree in **postorder** and flag nodes
    def flag_node!(node)
      node.children.each do |child|
        flag_node!(child)
      end

      case node
      when Tag
        if node.close_tag?
          node.flag = node.pair_tag.flag 
        else
          case node.i18n_attr
          when :i, :n
            node.flag = :ignore
          when :s
            node.flag = :phrase
          else
            if node.inline_tag?
              if node.self_close?
                node.flag = :candidate
              else
                if node.children.any? { |child| child.flag == :ignore }
                  node.flag = :ignore
                else
                  node.flag = :candidate
                end
              end
            else
              node.flag = :ignore
            end
          end
        end
      when Fold
        [node, node.name]
        if node.name == 'erb_expression'
          node.flag = :candidate
        else
          node.flag = :ignore
        end
      when Text
        if node.i18n_attr == :i
          node.flag = :ignore
        elsif node.prev_sibling.class == Fold && node.prev_sibling.name == 'erb_do'
          node.flag = :ignore
        elsif node.content.gsub(HTML_ENTITY_PATTERN, '') =~ /[[:graph:]]/u
          node.flag = :phrase
        else
          node.flag = :candidate
        end
      end
    end

    # Traverse tree in **preorder** and flag settle flag for candidate nodes
    def flag_canditate_node!(node)
      if node.flag == :candidate
        if node.parent.flag == :phrase
          node.flag = :phrase
        elsif node.prev_sibling && node.prev_sibling.flag == :phrase ||
              node.next_sibling && node.next_sibling.flag == :phrase
          node.flag = :phrase
        elsif node.children.count { |child| child.is_a?(Tag) && child.open_tag? } > 1
          node.flag = :ignore
          node.children.each do |child|
            child.flag = :phrase
          end
        else
          node.flag = :ignore
        end
      end

      node.children.each do |node|
        flag_canditate_node!(node)
      end
    end
  end
end
