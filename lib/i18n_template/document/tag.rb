module I18nTemplate
  class Document

    class Tag < Node
      def initialize(content, name, closing)
        super(content)
        @name    = name
        @closing = closing

        @closing = :self if content[content.size-2, 2] == '/>' || SELF_CLOSE_TAGS.include?(name)
        @i18n_attr = $1.to_sym if content =~ I18N_ATTR_PATTERN
      end

      attr_reader :name

      attr_reader :closing

      attr_accessor :pair_tag

      def open_tag?
        closing == nil
      end

      def close_tag?
        closing == :close
      end

      def self_close?
        closing == :self
      end

      def inline_tag?
        INLINE_TAGS.include?(name)
      end

      def prev_sibling
        sibling = super or return nil
        sibling == pair_tag ? pair_tag.prev_sibling : sibling
      end

      def next_sibling
        sibling = super or return nil
        sibling == pair_tag ? pair_tag.next_sibling : sibling
      end

      def inspect
        "<#Tag##{object_id} @name=#{@name.inspect}, @closing=#{@closing.inspect}, @i18n_attr=#{@i18n_attr.inspect}, @content=#{@content.inspect}, @flag=#{@flag.inspect}>"
      end
    end

  end
end
