require './test/test_helper'

describe I18nTemplate::Document, "#build_content_nodes" do
  let(:document) { I18nTemplate::Document.new("") }

  subject { document.send :build_content_nodes, @content }

  it "should build 2 nodes for TEXT with block fold" do
    @fold = "#{I18nTemplate::FOLD_START}0:block#{I18nTemplate::FOLD_END}"
    @content = "TEXT #{@fold}"

    assert_equal(2, subject.size)
    assert_equal(I18nTemplate::Document::Text, subject[0].class)
    assert_equal(I18nTemplate::Document::Fold, subject[1].class)
    assert_equal("TEXT ", subject[0].content)
    assert_equal(@fold, subject[1].content)
  end

  it "should build 2 nodes for TEXT with inline fold" do
    @fold = "#{I18nTemplate::FOLD_START}0:inline#{I18nTemplate::FOLD_END}"
    @content = "TEXT #{@fold}"

    assert_equal(2, subject.size)
    assert_equal(I18nTemplate::Document::Text, subject[0].class)
    assert_equal(I18nTemplate::Document::Fold, subject[1].class)
    assert_equal("TEXT ", subject[0].content)
    assert_equal(@fold, subject[1].content)
  end

  it "should build 3 nodes for text with two folds" do
    @fold0 = "#{I18nTemplate::FOLD_START}0:block#{I18nTemplate::FOLD_END}"
    @fold1 = "#{I18nTemplate::FOLD_START}1:block#{I18nTemplate::FOLD_END}"
    @content = "#{@fold0}TEXT#{@fold1}"

    assert_equal(3, subject.size)
    assert_equal(I18nTemplate::Document::Fold, subject[0].class)
    assert_equal(I18nTemplate::Document::Text, subject[1].class)
    assert_equal(I18nTemplate::Document::Fold, subject[2].class)
    assert_equal(@fold0, subject[0].content)
    assert_equal('TEXT', subject[1].content)
    assert_equal(@fold1, subject[2].content)
  end

  it "should build 2 nodes for content only with 2 folds" do
    @fold0 = "#{I18nTemplate::FOLD_START}0:block#{I18nTemplate::FOLD_END}"
    @fold1 = "#{I18nTemplate::FOLD_START}1:block#{I18nTemplate::FOLD_END}"
    @content = "#{@fold0}#{@fold1}"

    assert_equal(2, subject.size)
    assert_equal(I18nTemplate::Document::Fold, subject[0].class)
    assert_equal(I18nTemplate::Document::Fold, subject[1].class)
    assert_equal(@fold0, subject[0].content)
    assert_equal(@fold1, subject[1].content)
  end

  it "should build 3 nodes for folds with blank text" do
    @fold0 = "#{I18nTemplate::FOLD_START}0:block#{I18nTemplate::FOLD_END}"
    @fold1 = "#{I18nTemplate::FOLD_START}1:block#{I18nTemplate::FOLD_END}"
    @content = "#{@fold0} #{@fold1}"

    assert_equal(3, subject.size)
    assert_equal(I18nTemplate::Document::Fold, subject[0].class)
    assert_equal(I18nTemplate::Document::Text, subject[1].class)
    assert_equal(I18nTemplate::Document::Fold, subject[2].class)
    assert_equal(@fold0, subject[0].content)
    assert_equal(' ', subject[1].content)
    assert_equal(@fold1, subject[2].content)
  end

  it "should build only 1 text node when content does not have folds" do
    @content = " Hello World "

    assert_equal(1, subject.size)
    assert_equal(I18nTemplate::Document::Text, subject[0].class)
    assert_equal(@content, subject[0].content)
  end
end
