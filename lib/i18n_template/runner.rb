require 'i18n_template/runner/base'
require 'i18n_template/runner/extract_phrases'

require 'optparse'
module I18nTemplate
  module Runner
    class << self

      def run
        options = {}

        option_parser = OptionParser.new do |op|
          op.banner = "Usage: #{File.basename($0)} COMMAND [OPTIONS]"

          I18nTemplate.runners.each do |runner|
            op.separator ""
            op.separator "#{runner.command} - #{runner.description}"
            runner.add_options!(op, options)
          end

          op.separator ""
          op.on(
            "--verbose",
            "turn on verbosity"
          ) { |v| options[:verbose] = true }

          op.separator ""
          op.on_tail("-h", "--help", "Show this message") { puts op; exit }
          op.on_tail('-v', '--version', "Show version")   { puts I18nTemplate::VERSION; exit }
        end

        begin
          option_parser.parse!(ARGV)
        rescue OptionParser::ParseError => e
          warn e.message
          puts option_parser
          exit 1
        end

        I18nTemplate.runners.each do |runner|
          runner.default_options.each do |key, value|
            options[key] = value unless options.key?(key)
          end
        end

        command = ARGV.first

        runner = I18nTemplate.runners.detect { |klass| klass.command == command }

        unless runner
          warn "Unknown command '#{command}'"
          puts option_parser
          exit 1
        end

        runner.new(options).run
      end
    end

  end
end
