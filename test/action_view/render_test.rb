# encoding: UTF-8
require './test/test_helper'

class RenderTest < ActionView::TestCase
  include I18nTestCaseHelper

  def test_render_inline_with_assigns
    template = '<div><span>Comments count</span>: <%= @post.comments.count %></div>'

    add_translation '[1]Comments count[/1]: {1}', '[1]Anzahl die Kommentare[/1]: {1}'

    @post = Object.new
    @post.instance_eval do
      def comments
        %w(one two three)
      end
    end

    result = '<div><span>Anzahl die Kommentare</span>: 3</div>'

    render :inline => template, :type => :erb

    assert_equal(result, rendered)
  end

  def test_partial_rendering_wo_translations
    @current_year = 2011

    render :partial=> 'footer'

    assert_equal(<<-DATA, rendered)
<div>
  ~Copyright 2011. All rights reserved.
</div>
DATA
  end

  def test_file_rendering
    @user_name = 'Jack Daniels'

    add_translation %q(Hello {1}, {2}), %q(Привет {1}, {2})

    render :file => 'greeting', :locals => {
      :message => "Nice day today!"
    }

    assert_equal(<<-DATA, rendered)
<h2>Привет Jack Daniels, Nice day today!</h2>
DATA
  end

  def test_file_with_layout_rendering
    @user_names = %w(bob alice)

    render :file => 'users/index', :layout => 'layouts/application'

    assert_equal(<<-DATA, rendered)
<html>
  <body>
    <ul>
    <li>bob</li>
    <li>alice</li>
</ul>

  </body>
</html>
DATA
  end

  def test_file_with_partials_rendering
    @account = { :email => 'jack@daniels.com' }
    @profile = { :first_name => 'Jack', :last_name => 'Daniels' }

    add_translation %q([1]Email[/1]: {1}), %q([1]Мыло[/1]: {1})
    add_translation %q([1]First name[/1]: {1}), %q([1]Имя[/1]: {1})
    add_translation %q([1]Last name[/1]: {1}), %q([1]Фамилия[/1]: {1})

    render :file => 'users/show'

    assert_equal(<<-DATA, rendered)
<div>
<div>
  <strong>Мыло</strong>: jack@daniels.com
</div>

<p>
  <strong>Имя</strong>: Jack
</p>
<p>
  <strong>Фамилия</strong>: Daniels
</p>

</div>
DATA
  end

end

