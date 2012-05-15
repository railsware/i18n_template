module I18nTemplate
  class Document
    class Phrase
      def initialize
        @nodes = []
        @phrase = ""

        @attributes = ActiveSupport::OrderedHash.new

        @wrappers_count = 0

        @variables_count = 0

        @wrappers_count_stack = []

        @phrase_stack = []
      end

      attr_reader :phrase, :attributes

      def add_node(node)
        @nodes << node
      end

      def build!
        @nodes.each do |node|
          case node
          when Tag
            case node.closing
            when nil
              @wrappers_count += 1

              attr_key = "[#{@wrappers_count}]"

              @wrappers_count_stack.push(@wrappers_count)
            when :self
              @wrappers_count += 1

              attr_key = "[#{@wrappers_count}/]"
            when :close
              count = @wrappers_count_stack.pop

              attr_key = "[/#{count}]"
            end

            @phrase << attr_key
            @attributes[attr_key] = node.content

          when Fold
            @variables_count += 1

            attr_key = "{#{@variables_count}}"

            @phrase << attr_key
            @attributes[attr_key] = node.content

          when Text
            @phrase << I18nTemplate.escape(node.content).dup
          end
        end

        @phrase.sub!(/\A(\s*)/, '')
        @prefix = $1.to_s

        @phrase.sub!(/(\s*)\Z/, '')
        @suffix = $1.to_s

        @phrase.gsub!(/[\t\r\n]+/, ' ')
      end

      def to_eruby
        output = ""

        output << @prefix

        if @attributes.present?
          output << "<%- i18n_values = {} -%>"

          @attributes.each do |key, value|
            output << "<%- i18n_values['#{key}'] = capture do -%>#{value}<%- end -%>"
          end

          output << "<%= I18nTemplate.t(#{phrase.inspect}, i18n_values) %>"
        else
          output << "<%= I18nTemplate.t(#{phrase.inspect}) %>"
        end

        output << @suffix

        output
      end
    end
  end
end
