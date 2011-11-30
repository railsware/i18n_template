require 'i18n_template/extractor'

module I18nTemplate
  module Runner
    class ExtractPhrases < Base

      # register runner
      I18nTemplate.runners << self

      class << self
        def command
          'extract_phrases'
        end

        def description
          'extract phrases for translations'
        end

        def default_options
          @default_options ||= I18nTemplate.extractors.inject({}) { |result, klass|
            result.merge!(klass.default_options)
          }
        end

        def add_options!(parser, options)
          formats = I18nTemplate.extractors.map { |klass| klass.format }

          parser.on(
            "--format #{formats.join('|')}",
            "translation format (default #{default_options[:format]})"
          ) { |v| options[:format] = v }

          parser.on(
            "--po-root PO ROOT",
            "root directly for po files (default #{default_options[:po_root]})"
          ) { |v| options[:po_root] = v }

          parser.on(
            "--glob GLOB",
            "template files glob (default #{default_options[:glob].join(',')})"
          ) { |v| (options[:glob] ||= []) << v }

          parser.on(
            "--textdomain TEXTDOMAIN",
            "gettext textdomain (default #{default_options[:textdomain]})"
          ) { |v| options[:textdomain] = v }

          parser.on(
            "--output-file FILE",
            "output file (default #{default_options[:output_file]})"
          ) { |v| options[:output_file] = v }

          parser.on(
            "--locales-root DIRECTORY",
            "locales directory (default #{default_options[:locales_root]})"
          ) { |v| options[:locales_root] = v }
        end
      end

      def run
        paths = Dir[*@options[:glob]]

        extractor = I18nTemplate.extractors.detect { |klass| klass.format == @options[:format] }
        extractor or abort "Unknown extract format: #{@options[:format]}"
        extractor.new(@options).call(paths)
      end

    end
  end
end
