module I18nTemplate
  class Railtie < ::Rails::Railtie
    config.i18n_template = ActiveSupport::OrderedOptions.new

    initializer "i18n_template.register_template_handler" do
      options = config.i18n_template[:handler] || {}
      ActionView::Template.register_template_handler(:erb, I18nTemplate::Handler.new(options))
    end

    initializer "i18n_template.register_translator" do
      translator = config.i18n_template[:translator] || I18nTemplate::Translator::I18n
      I18nTemplate.register_translator(translator)
    end

    rake_tasks do
      require 'i18n_template/tasks'
    end
    
  end
end if defined?(Rails::Railtie)
