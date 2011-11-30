module I18nTemplate
  module Extractor
    # Extract phrases to plain format:
    # Each phrase per line
    class Plain < Base

      I18nTemplate.extractors << self

      class << self
        def format
          'plain'
        end

        def default_options
          super.merge({
            :output_file => 'phrases.txt'
          })
        end
      end

      def call(paths)
        sources = {}

        paths.each do |path|
          phrases = extract_phrases(path)
          phrases.each do |phrase|
            sources[phrase] ||= []
            sources[phrase] << path 
          end
        end

        log "Extracting #{sources.keys.size} phrases to #{@options[:output_file]}"
        File.open(@options[:output_file], "w") do |f|
          sources.sort.each do |phrase, paths|
            f << "# #{paths.join(",")}\n"
            f << phrase
            f << "\n"
          end
        end
      end
    end
  end
end
