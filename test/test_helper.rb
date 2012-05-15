$KCODE='u' if RUBY_VERSION < '1.9'

Bundler.setup

require 'test/unit'

require 'minitest/autorun'
require 'minitest/pride'

require 'i18n_template'

require 'action_controller'
require 'action_view/test_case'

ActionController::Base.view_paths = ['test/views']

ActionView::Template.register_template_handler(:erb, I18nTemplate::Handler.new)

I18nTemplate.debug = ENV['DEBUG']

module I18nTestCaseHelper
  def setup
    super
    I18n.backend.send(:translations).clear
  end

  def add_translation(key, value)
    I18n.backend.store_translations(I18n.locale, {
      key => value
    })
  end
end
