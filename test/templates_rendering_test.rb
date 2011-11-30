# encoding: UTF-8
require 'abstract_unit'

class TemplatesRenderingTest < ActionView::TestCase
  include I18nTestCaseHelper

  def setup
    ActionController::Base.view_paths = ['test/templates']
  end

  def test_partial_rendering_wo_translations
    @current_year = 2011

    render :partial=> 'footer'

    assert_equal(<<-DATA, rendered)
<div>~Copyright 2011. All rights reserved.</div>
DATA
  end

  def test_file_rendering
    @user_name = 'Jack Daniels'

    add_translation 'Hello {user name}, {message}',
                    'Привет {user name}, {message}'

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
    add_translation '[1]Email[/1]: {account email}',
                    '[1]Мыло[/1]: {account email}'

    add_translation '[1]First name[/1]: {profile first name}',
                    '[1]Имя[/1]: {profile first name}'

    add_translation '[1]Last name[/1]: {profile last name}',
                    '[1]Фамилия[/1]: {profile last name}'

    @account = { :email => 'jack@daniels.com' }
    @profile = { :first_name => 'Jack', :last_name => 'Daniels' }

    render :file => 'users/show'

    assert_equal(<<-DATA, rendered)
<div>
  <div><strong>Мыло</strong>: jack@daniels.com</div>

  <p><strong>Имя</strong>: Jack</p>
<p><strong>Фамилия</strong>: Daniels</p>

</div>
DATA
  end

end

