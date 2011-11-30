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
