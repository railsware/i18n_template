# encoding: UTF-8
require 'abstract_unit'

class InlineRenderingTest < ActionView::TestCase
  include I18nTestCaseHelper

  def test_assigns
    template = '<div>Comments count: <%= @post.comments.count %></div>'

    add_translation 'Comments count: {post comments count}',
                    'Anzahl die Kommentare: {post comments count}'

    @post = Object.new
    @post.instance_eval do
      def comments
        %w(one two three)
      end
    end

    result = '<div>Anzahl die Kommentare: 3</div>'

    render :inline => template, :type => :erb

    assert_equal(result, rendered)
  end

end
