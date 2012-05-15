module I18nTemplate
  class Document

    class Fold < Node
      def initialize(content, name)
        super(content)
        @name = name
      end

      attr_reader :name

      def inspect
        "<#Fold##{object_id} @name=#{@name} @content=#{@content.inspect}, @flag=#{@flag.inspect}>"
      end
    end

  end
end
