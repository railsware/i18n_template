require './test/test_helper'

describe I18nTemplate::Document, "#build_tree!" do
  let(:document) { I18nTemplate::Document.new(@source) }

  subject { document.send :build_tree! }

  it "should phrase 'i' attr" do
    @source = "<div data-i18n=\"i\"></div>"
    subject
    assert_equal(:i, document.nodes[1].i18n_attr)
  end

  it "should phrase 'n' attr" do
    @source = "<div data-i18n=\"n\"></div>"
    subject
    assert_equal(:n, document.nodes[1].i18n_attr)
  end

  it "should phrase 's' attr" do
    @source = "<div data-i18n=\"s\"></div>"
    subject
    assert_equal(:s, document.nodes[1].i18n_attr)
  end

  it "should NOT phrase 'x' attr" do
    @source = "<div data-i18n=\"x\"></div>"
    subject
    assert_equal(nil, document.nodes[1].i18n_attr)
  end
end
