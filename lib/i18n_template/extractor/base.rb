require "fileutils"

module I18nTemplate
  module Extractor
    class Base
      class << self
        def default_options
          {
            :glob       => ['app/views/**/*.html.erb}'],
            :format     => 'gettext'
          }
        end
      end

      def initialize(options)
        @options = self.class.default_options.dup
        @options.merge!(options)
      end

      def call(source)
        raise NotImplementedError, "'call' is not implemented by #{self.class.name}"
      end

      protected

      def log(message)
        puts message if @options[:verbose]
      end

      def extract_phrases(filename)
        log "Processing #{filename}"
        source = File.read(filename)
        document = ::I18nTemplate::Document.new(source)
        document.process!

        document.errors.each { |message| log(message) } if @options[:verbose]

        document.phrases
      end

    end
  end
end

