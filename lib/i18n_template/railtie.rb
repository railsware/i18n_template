module I18nTemplate
  class Railtie < ::Rails::Railtie
    rake_tasks do
      require 'i18n_template/tasks'
    end
  end
end if defined?(Rails::Railtie)
