module I18nTemplate
  class Document

    class Text < Node
      def inspect
        "<#Text##{object_id} @content=#{@content.inspect}, @i18n_attr=#{@i18n_attr.inspect}, @flag=#{@flag.inspect}>"
      end
    end

  end
end
