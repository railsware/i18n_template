$KCODE='u' if RUBY_VERSION < '1.9'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'i18n_template'

require 'action_controller'
require 'action_view/test_case'

require 'support/i18n_test_case_helper'

ActionView::Template.register_template_handler(:erb, I18nTemplate::Handler.new)
