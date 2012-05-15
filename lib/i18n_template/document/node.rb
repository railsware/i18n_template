module I18nTemplate
  class Document

    class Node
      def initialize(content = nil)
        @content  = content

        @children = []
      end

      attr_reader :content
      attr_reader :children
      attr_accessor :parent

      def prev_sibling
        return nil unless parent
        index = parent.children.index(self)
        return nil if index == 0
        parent.children[index - 1]
      end

      def next_sibling
        return nil unless parent
        index = parent.children.index(self)
        return nil if index == parent.children.size
        parent.children[index + 1]
      end

      attr_accessor :i18n_attr
      def inherit_i18n_attr(another)
        if @i18n_attr.nil? && another.i18n_attr == :i
          @i18n_attr = another.i18n_attr
        end
      end

      def to_eruby
        content
      end

      def inspect
        "#<Node @content=#{@content.inspect}, @flag=#{@flag}>"
      end

      attr_accessor :flag

      def phrase?
        flag == :phrase
      end
    end

  end
end
