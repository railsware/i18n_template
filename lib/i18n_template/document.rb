# encoding: UTF-8
require 'active_support'
require 'active_support/core_ext/string'
require 'action_controller/vendor/html-scanner/html/tokenizer'

module I18nTemplate
  ##
  # I18nTemplate::Document processes on the fly xhtml document internationalization.
  #
  # @example 
  #
  # Next document will be automatically internationalized 
  #
  #    <body>
  #      <% current_year = Time.now.year %>
  #      <span i18n="p">hello</span>
  #      <h2>Dashboard</h2>
  #      <div>Posts count: <%= current_user.posts.count %></div>
  #      <div>Click<a href="#">here</a></div>
  #    </body>
  #
  # to:
  #
  #    <body>
  #      <% current_year = Time.now.year %>
  #      <span>
  #        <%- i18n_variables = {}; i18n_wrappers = [] -%>
  #        <%= ::I18nTemplate::Translation.translate("hello", i18n_wrappers, i18n_variables) %>
  #      </span>
  #      <h2>
  #        <%- i18n_variables = {}; i18n_wrappers = [] -%>
  #        <%= ::I18nTemplate::Translation.translate("Dashboard", i18n_wrappers, i18n_variables) %>
  #       </h2>
  #      <div>
  #        <%- i18n_variables = {}; i18n_wrappers = [] -%>
  #        <%- i18n_variables['current user posts count'] = capture do -%>
  #          <%= current_user.posts.count %>
  #        <%- end -%>
  #        <%= ::I18nTemplate::Translation.translate("Posts count: {current user posts count}",
  #            i18n_wrappers, i18n_variables) %>
  #      </div>
  #      <div>
  #        <%- i18n_variables = {}; i18n_wrappers = [] -%>
  #        <%- i18n_wrappers[1] = capture do -%>
  #          <a href="#" i18n_wrapper="1">
  #            <%- i18n_variables = {}; i18n_wrappers = [] -%>
  #            <%= ::I18nTemplate::Translation.translate("here", i18n_wrappers, i18n_variables) %>
  #          </a>
  #        <%- end -%>
  #        <%= ::I18nTemplate::Translation.translate("Click[1]here[/1]", i18n_wrappers, i18n_variables) %>
  #       </div>
  #    </body>
  #
  # So you need just tp translate next phrases:
  #
  # * _hello_
  # * _Dashboard_
  # * _Posts count: {current user posts count}_
  # * _Click[1]here[/1]_
  #
  # I18n special markup element/attributes:
  #
  # * <i18n>content</i18n> - mark invisible for parser content for internationalization
  # * <... i18n="i" ...>content<...>  - (ignore) ignore element content internationalization
  # * <... i18n="p" ...>content<...>  - (phrase) explicitly enable content internationalization
  # * <... i18n="s" ...>content<...>  - (subphrase) mark element content as subphrase for parent element phrase
  #
  # Internal i18n element/attributes/scriptlets:
  #
  # * < ... i18n_phrase="phrase content" ...> - set extracted phrase into attribute
  # * < ... i18n_wrapper="position" ...> - mark element as wrapper as position in i18n_wrappers array
  # * <i18n_variable name="variable name">variable value</i18n_variable> - holds captured variable value with specified variable name from i18n_variables hash
  # * <% i18n_wrappers %> - array of captured wrapper contents
  # * <% i18n_variables %> - hash of name-value where name is variable name and value is captured variable value

  class Document
    # a symbol that means fold start
    FOLD_START = [0x2264].pack("U*").freeze

    # a symbol that means fold end
    FOLD_END = [0x2265].pack("U*").freeze

    # folds mapping
    FOLDS = [
      [ 'ignore', /<!DOCTYPE--.+?-->/m           ],
      [ 'ignore', /<script[^>]*?>.+?<\/script>/m ],
      [ 'ignore', /<!--.+?-->/m                  ],
      [ 'ignore', /<style[^>]*?>.+?<\/style>/m   ],
      [ 'eval',   /<select.+?<\/select>/m        ],
      [ 'ignore', /<%[^=](.*?)%>/m               ],
      [ 'eval',   /<%=(.*?)%>/m                  ]
    ].freeze

    # $1 - fold index
    # $2 - fold type e.g (eval, ignore)
    FOLD = /#{FOLD_START}(\d+):(\w+)#{FOLD_END}/.freeze

    # $1 tag name. E.g a-b:c_d
    OPEN_TAG   = /^<(\w+(:[\w_-]+)?)/.freeze

    # $1 tag name. E.g a-b:c_d
    CLOSED_TAG = /<\/(\w+(:[\w_-]+)?)>/.freeze

    SELF_CLOSE = /\/>$/.freeze

    BLOCK_TAGS = %w(
      i18n address blockquote p div h1 h2 h3 h4 h5 h6 li dd dt td th a
      legend label title caption option optgroup button
    ).freeze

    # &#169; &copy;
    HTML_ENTITY = /&(#\d+|\w+);/

    # processed document source
    attr_reader :source

    # array of processing warings
    attr_reader :warnings

    # array of folds
    attr_reader :folds

    # array of translation phrases
    attr_reader :phrases

    # root document node
    attr_reader :root_node

    # stack of document nodes
    attr_reader :node_stack

    # Initialize document processor
    # @param [String] document a pure html/xml document or erb template
    def initialize(source)
      @source = source.dup
      @warnings = []
      @folds = []
      @phrases = []
    end

    # Pre process document:
    # * add translation key attributes
    # * extract translation phrases
    # * modify document source
    # @return true
    def preprocess!
      raise "Document is already preprocessed" if @preprocessed

      fold_special_tags!

      parse_nodes do |node|
        set_node_phrase(node)
      end

      @source = ""
      @node_stack.each do |node| 
        @source << node_to_text(node)
      end

      @preprocessed = true
    end

    # Processs a document:
    # * expand translation keys
    # * modify document source
    def process!
      raise "Document is already processed" if @processed

      preprocess!
      parse_nodes

      @source = ""
      @root_node.children.each { |node| translate_node(node) }
      unfold_special_tags!

      @processed = true
    end

    # return true if document is preprocessed?
    def preprocessed?
      @preprocessed
    end

    # return true if document is processed?
    def processed?
      @processed
    end

    protected

    # convert special tags to string FOLD_STARTindex:nameFOLD_END
    # push tag and content to folds array
    def fold_special_tags!
      @folds = []

      FOLDS.each do |name, pattern|
        @source.gsub!(pattern) do |content|
          fold = "#{FOLD_START}#{@folds.size}:#{name}#{FOLD_END}"
          @folds << content
          fold
        end
      end
    end

    # replace FOLD_STARTindex:nameFOLD_END with @folds[index]
    def unfold_special_tags!
      @source.gsub!(FOLD) { @folds[$1.to_i] }
    end

    def parse_nodes
      @root_node = Node.new(nil, 0, 0, "ROOT", "ROOT") { @parent = self }
      @node_stack = []
      current_node = @root_node

      tokenizer = ::HTML::Tokenizer.new(@source)

      while token = tokenizer.next
        case token
        when OPEN_TAG
          node = Node.new(current_node, tokenizer.line, tokenizer.position, token, $1)
          @node_stack.push node
          current_node.children.push node
          current_node = node unless token =~ SELF_CLOSE
        when CLOSED_TAG
          node = Node.new(current_node, tokenizer.line, tokenizer.position, token, $1)
          warn("EXTRA CLOSING TAG:#{node.tag}, UP:#{current_node.token}", node.line) unless current_node.token[1, node.tag.size] == node.tag
          @node_stack.push node
          current_node = current_node.parent
        else
          node = Node.new(current_node, tokenizer.line, tokenizer.position, token)
          @node_stack.push node
          current_node.children.push node
        end

        yield @node_stack.last if block_given?
      end
    end

    # Escape next characters:
    # * '[' - [lsb] left square bracket
    # * ']' - [rsb] right square bracket
    # * '{' - [lcb] left curly bracket
    # * '}' - [rcb] right curly bracket
    # * '#' - [ns]  number sign
    def escape_phrase(phrase)
      phrase.gsub(/(\[|\]|\{|\}|#)/) do |char| 
        case char
        when '[' then '[lsb]'
        when ']' then '[rsb]'
        when '{' then '[lcb]'
        when '}' then '[rcb]'
        when '#' then '[ns]'
        else 
          char
        end
      end
    end

    def set_node_phrase(node)
      return if node.tag?
      return if node.token.blank?
      return if node.token.split(/\s+/).all? { |v| v =~ HTML_ENTITY }

      phrase = node.token.dup
      phrase.gsub!(/"/, '&quot;')
      phrase.gsub!(/\r\n/, ' ')
      phrase.gsub!(/\s+/, ' ')
      phrase.strip!


      until node.parent.root?
        break if node.phrase ||
          node.token =~ /i18n="(p|i)"/ ||
          (BLOCK_TAGS.include?(node.tag) && node.token !~ /i18n="s"/)
        node = node.parent
      end
      return if node.token =~ /i18n="i"/

      node.phrase ||= ''
      node.phrase << " " << phrase
    end

    def node_to_text(node)
      node_text = node.token.dup
      node_text.gsub!(FOLD) { @folds[$1.to_i] }

      return node_text if node.phrase.nil? || node.phrase.strip.split(/ /).all? { |value| value =~ FOLD }

      # push down phrase for cases like <div><span><span>Text</span></span></div>
      if node.children.first && node.children.first.tag? &&
        (node.children.size == 1 || node.wrapped_node_text)
        node.children.first.phrase = node.phrase
        node.phrase = nil
        return node_text
      end

      # allowed fold indices
      fold_indices = []
      node.phrase.scan(FOLD).each do |index, type|
        next unless type == 'eval'
        fold_indices.push(index.to_i)
      end

      phrase = ""
      wrap_counter = 0
      node.children.each do |child|
        if child.text?
          #phrase << unfold_text(child.token, fold_indices)
          text = escape_phrase(child.token)
          phrase << text
        elsif child.tag == 'br'
          phrase << "[nl]"
        else
          wrap_counter += 1
          child.token.sub!(/>$/, " i18n_wrapper=\"#{wrap_counter}\">")
          if text = child.wrapped_node_text
            #text = unfold_text(text, fold_indices)
            phrase << "[#{wrap_counter}]#{text}[/#{wrap_counter}]"
          else
            text = child.descendants_text
            #text = unfold_text(node.descendants_text, fold_indices)
            phrase << "NNODE[#{wrap_counter}]#{text}[/#{wrap_counter}]"
          end
        end
      end

      # unfold phrase
      unfold_text!(phrase, fold_indices)

      # wrap variables in text nodes
      wrap_variables(node, fold_indices)

      phrase.gsub!(/\s+/, ' ')
      phrase.gsub!(/"/, '&quot;')
      phrase.strip!

      # append translation key attribute
      unless phrase.blank?
        @phrases << phrase
        node_text.sub!(/>$/) { " i18n_phrase=\"#{phrase}\">" }
      end

      node_text
    end

    def unfold_text!(text, fold_indices)
      text.gsub!(FOLD) do |string|
        index = $1.to_i

        if $2 == 'eval' && fold_indices.include?(index)
          '{' << fold_human_variable(index) << '}'
        else
          string
        end
      end
    end

    def wrap_variables(node, fold_indices)
      node.children.each do |child|

        child.token.gsub!(FOLD) do |string|
          index = $1.to_i
          if $2 == 'eval' && fold_indices.include?(index)
            "<i18n_variable name=\"" << fold_human_variable(index) << "\">#{string}</i18n_variable>"
          else
            string
          end
        end if child.text?

        wrap_variables(child, fold_indices)
      end
    end

    def fold_human_variable(index)
      fold = @folds[index]

      var = fold.dup
      var.sub!(/^<%=/, '')
      var.gsub!(/<\/?[^>]+>/, '')
      var.gsub!(/\W+/, ' ')
      var.gsub!(/_/, ' ')
      var.strip!
      parts = var.split(/\s+/)

      parts.shift if parts[0] == 'h' || parts[0] == 'render' || parts[0] == 'f' 
      parts.shift if parts[0] == 'partial'

      3.times { parts.shift } if parts[0,3] == ['check', 'box',    'tag']
      3.times { parts.shift } if parts[0,3] == ['radio', 'button', 'tag']
      3.times { parts.shift } if parts[0,3] == ['text', 'field',   'tag']
      2.times { parts.shift } if parts[0,2] == ['select', 'tag']

      variable = (parts.size > 3 ? parts[0,5] : parts).join(" ")
      warn "EMPTY VARIABLE:#{fold}" if variable.empty?
      variable
    end

    def translate_node(node, translate = true, notext = false)
      if node.text?
        @source << node.token unless notext
      else
        if node.token =~ /i18n_phrase/
          warn("NESTED T9N:#{node.tag} UP #{node.parent.token}", node.line) unless translate
          node.token.sub!(/ i18n_phrase="(.+?)"/, '')
          key = $1.dup
          node.token.sub!(/ i18n="p"/, '')

          warn("BLOCK NOT EXPANDED:#{node.token} #{key}", node.line) if key =~ FOLD
          warn("NODE MISSING:#{node.token} #{key}", node.line) if key =~ /NNODE/

          @source << node.token unless node.tag == 'i18n'

          @source << "<%- i18n_variables = {}; i18n_wrappers = [] -%>"
          node.children.each do |child|
            if child.tag?
              if child.token =~ /<i18n_variable name="(.*?)"/
                @source << "<%- i18n_variables['#$1'] = capture do -%>"
                translate_node(child.children.first, false, false)
                @source << "<%- end -%>"
              elsif child.token =~ /i18n_wrapper=\"(\d+)\"/
                @source << "<%- i18n_wrappers[#$1] = capture do -%>"
                translate_node(child, false, true)
                @source << "<%- end -%>"
              end
            end
          end

          @source << "<%= ::I18nTemplate::Translation.translate(#{key.inspect}, i18n_wrappers, i18n_variables) %>"
          @source << "</#{node.tag}>" unless node.tag == 'i18n' || node.tag[-2,2] == '/>'

          return
        elsif node.token =~ /<i18n_variable name="(.*?)"/
          @source << "<%- i18n_variables['#$1'] = capture do -%>"
          translate_node(node.children.first, false, false)
          @source << "<%- end -%>"

          return
        end

        @source << node.token.sub(/\s+i18n="i"/, '') unless node.tag == 'i18n'
        node.children.each do |child|
          translate_node(child, translate, notext)
        end
        @source << "</#{node.tag}>" unless node.tag == 'i18n' || node.tag[-2,2] == '/>'
      end
    end

    # Record waring
    # @param [String] message a message
    # @param [String] line (optional) a line in source
    def warn(message, line = nil)
      if line
        @warnings << "[SOURCE:#{line}]: #{message}"
      else
        @warnings << message
      end
    end

  end
end
