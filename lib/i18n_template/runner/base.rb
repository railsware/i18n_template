module I18nTemplate
  module Runner
    ##
    # Base runner class
    class Base
      class << self
        def add_options!(parser, options)
        end
      end

      def initialize(argv, options)
        @argv = argv
        @options = options
      end
    end
  end
end
