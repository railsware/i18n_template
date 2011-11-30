require 'yaml'

module I18nTemplate
  module Extractor
    # Extract phrases to yaml format. E.g:
    # config/locales/templates.yml
    class Yaml < Base

      I18nTemplate.extractors << self

      class << self
        def format
          'yaml'
        end

        def default_options
          super.merge({
            :locales_root => 'config/locales'
          })
        end
      end

      def call(paths)
        # ensure root directory exists
        FileUtils.mkdir_p(@options[:locales_root])
        output_file = File.join(@options[:locales_root], 'phrases.yml')

        # extract phrases
        phrases = []
        paths.each do |path|
          phrases += extract_phrases(path)
        end
        phrases.uniq!

        # update phrases
        log "Extracting #{phrases.size} phrases to #{output_file}"
        data = File.exists?(output_file) ? YAML.load_file(output_file) : {}
        data['en'] ||= {}
        data.keys.each do |locale|
          phrases.each do |phrase|
            data[locale][phrase] ||= nil
          end
        end

        # store data
        File.open(output_file, "w") do |f|
          f << data.to_yaml
        end
      end
    end
  end
end

