# encoding: UTF-8
require 'abstract_unit'

class DocumentTest < Test::Unit::TestCase
  include I18nTestCaseHelper

  def test_folds
    source =<<-DATA
<body>
  <h2>hello</h2>
  <div>hi <%= user.last_post.comments.size %> world</div>
  <!-- <div></div> -->
</body>
DATA

    document = I18nTemplate::Document.new(source)

    document.send :fold_special_tags!

    assert_equal(2, document.folds.size)
    assert_equal('<!-- <div></div> -->', document.folds[0])
    assert_equal('<%= user.last_post.comments.size %>', document.folds[1])
    assert_equal(<<-DATA, document.source)
<body>
  <h2>hello</h2>
  <div>hi ≤1:eval≥ world</div>
  ≤0:ignore≥
</body>
DATA

    document.send :unfold_special_tags!

    assert_equal(<<-DATA, document.source)
<body>
  <h2>hello</h2>
  <div>hi <%= user.last_post.comments.size %> world</div>
  <!-- <div></div> -->
</body>
DATA
  end

  def test_preprocess
    source =<<-DATA
<body>
  <% current_year = Time.now.year %>
  <span i18n="p">hello</span>
  <h2>Dashboard</h2>
  <div>Posts count: <%= current_user.posts.count %></div>
  <div>Click<a href="#">here</a></div>
</body>
DATA

    document = I18nTemplate::Document.new(source)
    document.preprocess!


    assert_equal([
      'hello',
      'Dashboard',
      'Posts count: {current user posts count}',
      'Click[1]here[/1]',
      'here'
    ], document.phrases)


    assert_equal(<<-DATA, document.source)
<body>
  <% current_year = Time.now.year %>
  <span i18n="p" i18n_phrase="hello">hello</span>
  <h2 i18n_phrase="Dashboard">Dashboard</h2>
  <div i18n_phrase="Posts count: {current user posts count}">Posts count: <i18n_variable name="current user posts count"><%= current_user.posts.count %></i18n_variable></div>
  <div i18n_phrase="Click[1]here[/1]">Click<a href=\"#\" i18n_wrapper="1" i18n_phrase="here">here</a></div>
</body>
DATA
  end

  def test_process
    source =<<-DATA
<body>
  <% current_year = Time.now.year %>
  <span i18n="p">hello</span>
  <h2>Dashboard</h2>
  <div>Posts count: <%= current_user.posts.count %></div>
  <div>Click<a href="#">here</a></div>
</body>
DATA
    
    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal(<<-DATA, document.source)
<body>
  <% current_year = Time.now.year %>
  <span><%- i18n_variables = {}; i18n_wrappers = [] -%><%= ::I18nTemplate::Translation.translate("hello", i18n_wrappers, i18n_variables) %></span>
  <h2><%- i18n_variables = {}; i18n_wrappers = [] -%><%= ::I18nTemplate::Translation.translate("Dashboard", i18n_wrappers, i18n_variables) %></h2>
  <div><%- i18n_variables = {}; i18n_wrappers = [] -%><%- i18n_variables['current user posts count'] = capture do -%><%= current_user.posts.count %><%- end -%><%= ::I18nTemplate::Translation.translate("Posts count: {current user posts count}", i18n_wrappers, i18n_variables) %></div>
  <div><%- i18n_variables = {}; i18n_wrappers = [] -%><%- i18n_wrappers[1] = capture do -%><a href="#" i18n_wrapper="1"><%- i18n_variables = {}; i18n_wrappers = [] -%><%= ::I18nTemplate::Translation.translate("here", i18n_wrappers, i18n_variables) %></a><%- end -%><%= ::I18nTemplate::Translation.translate("Click[1]here[/1]", i18n_wrappers, i18n_variables) %></div>
</body>
DATA

  end

  def test_render_partial
    source =<<-DATA
<div><%= render :partial => 'menu' %></div>
DATA

    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal(<<-DATA, document.source)
<div><%= render :partial => 'menu' %></div>
DATA
  end

  def test_br
    source =<<-DATA
<label for="merchant_address">Merchant address <br/>(required)</label>
DATA

    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal(<<-DATA, document.source)
<label for="merchant_address"><%- i18n_variables = {}; i18n_wrappers = [] -%><%= ::I18nTemplate::Translation.translate("Merchant address [nl](required)", i18n_wrappers, i18n_variables) %></label>
DATA
  end

  def test_good_nested
    source =<<-DATA
<div><span><span>This is</span></span> <%= message %></div>
DATA

    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal(<<-DATA, document.source)
<div><%- i18n_variables = {}; i18n_wrappers = [] -%><%- i18n_wrappers[1] = capture do -%><span i18n_wrapper="1"><span></span></span><%- end -%><%- i18n_variables['message'] = capture do -%><%= message %><%- end -%><%= ::I18nTemplate::Translation.translate("[1]This is[/1] {message}", i18n_wrappers, i18n_variables) %></div>
DATA
  end

  def test_bad_nested
    source =<<-DATA
<div><span><span>This</span>is</span><%= message %></div>
DATA
    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal(<<-DATA, document.source)
<div><%- i18n_variables = {}; i18n_wrappers = [] -%><%- i18n_wrappers[1] = capture do -%><span i18n_wrapper="1"><span></span></span><%- end -%><%- i18n_variables['message'] = capture do -%><%= message %><%- end -%><%= ::I18nTemplate::Translation.translate("NNODE[1]is[/1]{message}", i18n_wrappers, i18n_variables) %></div>
DATA
  end

  def test_extra_open_tags
    source =<<-DATA
<div>
  <h2>hello</h2>
  <p>
DATA

    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal([
    ], document.warnings)

    result =<<-DATA
<div>
  <h2><%- i18n_variables = {}; i18n_wrappers = [] -%><%= ::I18nTemplate::Translation.translate(\"hello\", i18n_wrappers, i18n_variables) %></h2>
  <p>
</p></div>
DATA

    assert_equal(result.strip, document.source)
  end

  def test_extra_close_tags
    source =<<-DATA
<div>
  <h2>hello</h2>
</div>
</div>
DATA

    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal([
      "[SOURCE:4]: EXTRA CLOSING TAG:div, UP:ROOT",
      "[SOURCE:4]: EXTRA CLOSING TAG:div, UP:ROOT"
    ], document.warnings)

    assert_equal(<<-DATA, document.source)
<div>
  <h2><%- i18n_variables = {}; i18n_wrappers = [] -%><%= ::I18nTemplate::Translation.translate(\"hello\", i18n_wrappers, i18n_variables) %></h2>
</div>

DATA
  end

  def test_select_tag
    source =<<-DATA
<div>
<select name="company">
  <option value="volvo">Volvo</option>
  <option value="saab">Saab</option>
  <option value="mercedes">Mercedes</option>
  <option value="audi">Audi</option>
</select>
</div>
DATA

    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal([], document.warnings)

    assert_equal(<<-DATA, document.source)
<div>
<select name="company">
  <option value="volvo">Volvo</option>
  <option value="saab">Saab</option>
  <option value="mercedes">Mercedes</option>
  <option value="audi">Audi</option>
</select>
</div>
DATA
  end

  def test_select_tag_form_helper
    source =<<-DATA
<div>
<label for="people">People</label>
<%= select_tag "people", options_from_collection_for_select(@people, "id", "name") %>
</div>
DATA

#--------------------------------------------------
#     puts "#"*80
#     require 'i18n_template/processor'
#     processor = I18nTemplate::Processor.new(source)
#     processor.process!
#     puts processor.template
#     p processor.phrases
#-------------------------------------------------- 

    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal([], document.warnings)
    assert_equal([
      'People'
    ], document.phrases)
    assert_equal(<<-DATA, document.source)
<div>
<label for="people"><%- i18n_variables = {}; i18n_wrappers = [] -%><%= ::I18nTemplate::Translation.translate("People", i18n_wrappers, i18n_variables) %></label>
<%= select_tag "people", options_from_collection_for_select(@people, "id", "name") %>
</div>
DATA
  end


  def test_nbsp_html_entity
    source =<<-DATA
<div style="clear:both">&nbsp;  &#169;</div>
DATA

#--------------------------------------------------
#     puts "#"*80
#     require 'i18n_template/processor'
#     processor = I18nTemplate::Processor.new(source)
#     processor.process!
#     puts processor.template
#     p processor.phrases
# 
#-------------------------------------------------- 
    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal([], document.warnings)
    assert_equal([], document.phrases)
    assert_equal(<<-DATA, document.source)
<div style="clear:both">&nbsp;  &#169;</div>
DATA
  end

  def test_text_with_braces
    source =<<-DATA
<div>hello {user}</div>
DATA

    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal([], document.warnings)
    assert_equal(['hello [lcb]user[rcb]'], document.phrases)
    assert_equal(<<-DATA, document.source)
<div><%- i18n_variables = {}; i18n_wrappers = [] -%><%= ::I18nTemplate::Translation.translate(\"hello [lcb]user[rcb]\", i18n_wrappers, i18n_variables) %></div>
DATA
  end

  def test_text_with_brackets
    source =<<-DATA
<div>hello [1] user [/1]</div>
DATA

    document = I18nTemplate::Document.new(source)
    document.process!

    assert_equal([], document.warnings)
    assert_equal(['hello [lsb]1[rsb] user [lsb]/1[rsb]'], document.phrases)
    assert_equal(<<-DATA, document.source)
<div><%- i18n_variables = {}; i18n_wrappers = [] -%><%= ::I18nTemplate::Translation.translate(\"hello [lsb]1[rsb] user [lsb]/1[rsb]\", i18n_wrappers, i18n_variables) %></div>
DATA
  end
end
