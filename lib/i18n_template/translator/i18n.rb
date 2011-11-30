require "i18n"

module I18nTemplate
  module Translator
    ##
    # Standard i18n translator for i18n_template
    class I18n

      # Special symbol for separator
      NO_SEPARATOR = [0x10308].pack('U*').freeze

      def self.call(phrase)
        self.new.call(phrase)
      end

      def call(phrase)
        ::I18n.translate(phrase, {
          :default   => "~#{phrase}",
          :separator => NO_SEPARATOR
        })
      end
    end
  end
end
