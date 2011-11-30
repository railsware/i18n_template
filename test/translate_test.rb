require 'abstract_unit'

class TranslateTest < Test::Unit::TestCase
  include I18nTestCaseHelper

  def test_wrappers
    key = "[1]Hello[/1] [2]World[/2]"
    translation = "[1]Hallo[/1] [2]die Welt[/2]"
    add_translation(key, translation)
    wrappers = []
    wrappers[0] = '<div i18n_wrapper="1"></div>'
    wrappers[1] = '<b i18n_wrapper="1"></b>'
    wrappers[2] = '<i i18n_wrapper="1"><sub></sub></i>'
    variables = []
    result = '<b>Hallo</b> <i><sub>die Welt</sub></i>'

    assert_equal(result, I18nTemplate::Translation.translate(key, wrappers, variables))
  end

  def test_variables
    key = "Hello {user}, {message}."
    translation = "{message}. Hallo {user}"
    add_translation(key, translation)

    wrappers = []
    variables = {
      'user'    => 'Jack',
      'message' => 'Nice day today' 
    }
    result = 'Nice day today. Hallo Jack'

    assert_equal(result, I18nTemplate::Translation.translate(key, wrappers, variables))
  end
  

  def test_translation_wo_brackets
    key = "[1]Hello[/1] [2]World[/2]"
    translation = "Hallo die Welt"
    add_translation(key, translation)
    wrappers = []
    wrappers[0] = '<div i18n_wrapper="1"></div>'
    wrappers[1] = '<b i18n_wrapper="1"></b>'
    wrappers[2] = '<i i18n_wrapper="1"><sub></sub></i>'
    variables = []
    result = 'Hallo die Welt'

    assert_equal(result, I18nTemplate::Translation.translate(key, wrappers, variables))
  end

  def test_translation_wo_braces
    key = "Hello {user}, {message}."
    translation = "message. Hallo user"
    add_translation(key, translation)

    wrappers = []
    variables = {
      'user'    => 'Jack',
      'message' => 'Nice day today' 
    }
    result = 'message. Hallo user'

    assert_equal(result, I18nTemplate::Translation.translate(key, wrappers, variables))
  end

  def test_replace_nl_with_br
    key = "Introduction.[nl]Hello!"
    result = "~Introduction.<br />Hello!"

    assert_equal(result, I18nTemplate::Translation.translate(key, [], {}))
  end
end
  
