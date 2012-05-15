module I18nTemplate
  module Runner
    class ShowTemplate < Base

      # register runner
      I18nTemplate.runners << self

      class << self
        def command
          'show_template'
        end

        def description
          'show processed template'
        end

        def example
          'path/to/erb/file'
        end

        def default_options
          @default_options ||= I18nTemplate.extractors.inject({}) { |result, klass|
            result.merge!(klass.default_options)
          }
        end
      end

      def run
        filename = ARGV[1]
        File.exists?(filename) or abort "Can't open #{filename.inspect}"
        document = I18nTemplate::Document.new(File.read(filename))
        document.process!

        puts document.source
      end

    end
  end
end
