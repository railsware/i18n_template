require "i18n_template/version"

module I18nTemplate
  autoload :Handler,     'i18n_template/handler'
  autoload :Translator,  'i18n_template/translator'
  autoload :Extractor,   'i18n_template/extractor'
  autoload :Runner,      'i18n_template/runner'
  autoload :Translation, 'i18n_template/translation'
  autoload :Document,    'i18n_template/document'
  autoload :Node,        'i18n_template/node'

  class << self
    def runners
      @runners ||= []
    end

    def extractors
      @extractors ||= []
    end

    def translator
     @translator ||= I18nTemplate::Translator::I18n
    end
    attr_writer :translator
  end
end

require "i18n_template/railtie"
