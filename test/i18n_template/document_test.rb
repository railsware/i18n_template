require './test/test_helper'
describe I18nTemplate::Document, "#process!" do
  let(:document) { I18nTemplate::Document.new(@source) }

  subject { document.process! }

  it "should errors" do
    @source = "<html><% %><style></style><div><span>hi</span></html>"

    subject

    assert_equal(false, subject)
    assert_equal(@source, document.source)
  end

  it "should one" do
    @source = "<div>Hello <span><b>world</b></span> today!</div>"
    result = ""
    result << "<div>"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['[1]'] = capture do -%><span><%- end -%>"
    result << "<%- i18n_values['[2]'] = capture do -%><b><%- end -%>"
    result << "<%- i18n_values['[/2]'] = capture do -%></b><%- end -%>"
    result << "<%- i18n_values['[/1]'] = capture do -%></span><%- end -%>"
    result << "<%= I18nTemplate.t(\"Hello [1][2]world[/2][/1] today!\", i18n_values) %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should two" do
    @source = "<div>Hello <span><b>world</b></span> today!<div>:)</div></div>"
    result = ""
    result << "<div>"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['[1]'] = capture do -%><span><%- end -%>"
    result << "<%- i18n_values['[2]'] = capture do -%><b><%- end -%>"
    result << "<%- i18n_values['[/2]'] = capture do -%></b><%- end -%>"
    result << "<%- i18n_values['[/1]'] = capture do -%></span><%- end -%>"
    result << "<%= I18nTemplate.t(\"Hello [1][2]world[/2][/1] today!\", i18n_values) %>"
    result << "<div>"
    result << "<%= I18nTemplate.t(\":)\") %>"
    result << "</div>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should 18n span span" do
    @source = "<div><span><span>Hello</span></span></div>"
    result = ""
    result << "<div><span><span>"
    result << "<%= I18nTemplate.t(\"Hello\") %>"
    result << "</span></span></div>"

    subject

    assert_equal(result, document.source)
  end

  it "should 18n span span span" do
    @source = "<div><span><span><span>Hello</span></span></span></div>"
    result = ""
    result << "<div><span><span><span>"
    result << "<%= I18nTemplate.t(\"Hello\") %>"
    result << "</span></span></span></div>"

    subject

    assert_equal(result, document.source)
  end

  it "should use two phrases for single inline elements" do
    @source = "<div><b>Hello</b><i>World</i></div>"
    result = ""
    result << "<div>"
    result << "<b>"
    result << "<%= I18nTemplate.t(\"Hello\") %>"
    result << "</b>"
    result << "<i>"
    result << "<%= I18nTemplate.t(\"World\") %>"
    result << "</i>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should 18n wrapped span" do
    @source = "<div><span><b>Hello</b><i>World</i></span></div>"
    result = ""
    result << "<div>"
    result << "<span>"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['[1]'] = capture do -%><b><%- end -%>"
    result << "<%- i18n_values['[/1]'] = capture do -%></b><%- end -%>"
    result << "<%- i18n_values['[2]'] = capture do -%><i><%- end -%>"
    result << "<%- i18n_values['[/2]'] = capture do -%></i><%- end -%>"
    result << "<%= I18nTemplate.t(\"[1]Hello[/1][2]World[/2]\", i18n_values) %>"
    result << "</span>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should dont_translate_style" do
    @source = "<style><span><b>Hello</b><i>World</i></span></style>"
    result = "<style><span><b>Hello</b><i>World</i></span></style>"

    subject

    assert_equal(result, document.source)
  end

  it "should NOT translate blank source" do
    @source =<<-EOF.strip
<div>

  <span>hello</span>
</div>
    EOF

    result =<<-EOF.strip
<div>

  <span><%= I18nTemplate.t(\"hello\") %></span>
</div>
    EOF

    subject

    assert_equal(result, document.source)
  end

  it "should wrap_variable" do
    @source = "<div>Hello <%= @user.name %></div>"

    result = ""
    result << "<div>"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['{1}'] = capture do -%><%= @user.name %><%- end -%>"
    result << "<%= I18nTemplate.t(\"Hello {1}\", i18n_values) %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should treat start eval erb as part of phrase" do
    @source = "<div><b><%= @user.name %></b> is logged in!</div>"
    result = ""
    result << "<div>"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['[1]'] = capture do -%><b><%- end -%>"
    result << "<%- i18n_values['{1}'] = capture do -%><%= @user.name %><%- end -%>"
    result << "<%- i18n_values['[/1]'] = capture do -%></b><%- end -%>"
    result << "<%= I18nTemplate.t(\"[1]{1}[/1] is logged in!\", i18n_values) %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should treat end eval erb as part of phrase" do
    @source = "<div>You are logged in as <b><%= @user.name %></b></div>"
    result = ""
    result << "<div>"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['[1]'] = capture do -%><b><%- end -%>"
    result << "<%- i18n_values['{1}'] = capture do -%><%= @user.name %><%- end -%>"
    result << "<%- i18n_values['[/1]'] = capture do -%></b><%- end -%>"
    result << "<%= I18nTemplate.t(\"You are logged in as [1]{1}[/1]\", i18n_values) %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should not internationalize erb eval inside block elements" do
    @source = "<div><%= @user.name %></div>"
    result = "<div><%= @user.name %></div>"

    subject

    assert_equal(result, document.source)
  end
  it "should escape brackets" do
    @source = "<div>Hello [1]hi[/1] [/2]</div>"
    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Hello [lsb]1[rsb]hi[lsb]/1[rsb] [lsb]/2[rsb]\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should escape braces" do
    @source = "<div>Hello {1}</div>"
    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Hello [lcb]1[rcb]\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should dont_escape_number_symbol" do
    @source = "<div>Hello #1</div>"
    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Hello #1\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should number_symbol_with_curly_brackets" do
    @source = '<div>Hello #{user}</div>'
    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Hello #[lcb]user[rcb]\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end


  it "should phrase_attr_ignore" do
    @source = "<div data-i18n=\"i\">Hello</div>"
    result = "<div data-i18n=\"i\">Hello</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should phrase_attr_ignore_and_new_phrase" do
    @source = "<div data-i18n=\"i\">Hello<span data-i18n=\"n\">World</span></div>"
    result = ""
    result << "<div data-i18n=\"i\">Hello"
    result << "<span data-i18n=\"n\">"
    result << "<%= I18nTemplate.t(\"World\") %>"
    result << "</span>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should phrase_attr_ignore_and_sub_phrase" do
    @source = "<div data-i18n=\"i\">Hello<span data-i18n=\"s\">World</span></div>"
    result = ""
    result << "<div data-i18n=\"i\">Hello"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['[1]'] = capture do -%><span data-i18n=\"s\"><%- end -%>"
    result << "<%- i18n_values['[/1]'] = capture do -%></span><%- end -%>"
    result << "<%= I18nTemplate.t(\"[1]World[/1]\", i18n_values) %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should phrase_attr_sub_phrase" do
    @source = "<div>Hello <div data-i18n=\"s\">World</div></div>"
    result = ""
    result << "<div>"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['[1]'] = capture do -%><div data-i18n=\"s\"><%- end -%>"
    result << "<%- i18n_values['[/1]'] = capture do -%></div><%- end -%>"
    result << "<%= I18nTemplate.t(\"Hello [1]World[/1]\", i18n_values) %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end
  
  it "should phrase_attr_new_phrase" do
    @source = "<div>Hello   <span data-i18n=\"n\">World</span></div>"
    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Hello\") %>"
    result << "   <span data-i18n=\"n\">"
    result << "<%= I18nTemplate.t(\"World\") %>"
    result << "</span>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should double_quote" do
    @source = "<div>\"Hello\" World</div>"
    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"[quot]Hello[quot] World\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should single_quote" do
    @source = "<div>'Hello' World</div>"
    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"'Hello' World\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should iso_code" do
    @source = "<div>Copyright &#169; 2012 Railsware</div>"
    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Copyright &#169; 2012 Railsware\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should html_code" do
    @source = "<div>Copyright &copy; 2012 Railsware</div>"
    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Copyright &copy; 2012 Railsware\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should skip_only_html_code_i18n" do
    @source = "<div>&#169; &#153; </div>"
    result = ""
    result << "<div>&#169; &#153; </div>"

    subject

    assert_equal(result, document.source)
  end
  
  it "should control \n\n characters in phrase" do
    @source = "<div>Hello\n\nWorld</div>"

    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Hello World\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should control \n\n characters in phrase" do
    @source = "<div>Hello\r\rWorld</div>"

    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Hello World\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should control \n\n characters in phrase" do
    @source = "<div>Hello\t\tWorld</div>"

    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Hello World\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should control \n\n characters in phrase" do
    @source = "<div>Hello\s\sWorld</div>"

    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Hello  World\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should preserve_layout" do
    @source =<<-EOF
<div>


Hello
<span>  World  </span>
</div>
    EOF

    result =<<-EOF
<div>


<%- i18n_values = {} -%><%- i18n_values['[1]'] = capture do -%><span><%- end -%><%- i18n_values['[/1]'] = capture do -%></span><%- end -%><%= I18nTemplate.t(\"Hello [1]  World  [/1]\", i18n_values) %>
</div>
    EOF

    subject

    assert_equal(result, document.source)
  end

  it "should i18n nested div" do
    @source =<<-DATA
<div>
  <div>
    <div>
      <span> &copy; </span>
    </div>
    <span>there</span>
  </div>
</div>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<div>
  <div>
    <div>
      <span> &copy; </span>
    </div>
    <span><%= I18nTemplate.t(\"there\") %></span>
  </div>
</div>
    DATA
  end

  it "should NOT break phrase with empty span" do
    @source = "<div>Hello <span> </span> there</div>"
    result = ""
    result << "<div>"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['[1]'] = capture do -%><span><%- end -%>"
    result << "<%- i18n_values['[/1]'] = capture do -%></span><%- end -%>"
    result << "<%= I18nTemplate.t(\"Hello [1] [/1] there\", i18n_values) %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should skip blank span at the end" do
    skip "Undefined semantic"
    @source = "<div>Hello <span></span></div>"
    result = ""
    result << "<div><%= I18nTemplate.t(\"Hello\") %> <span></span></div>"

    subject

    assert_equal(result, document.source)
  end

  it "should skip empty span at the end" do
    skip "Undefined semantic"
    @source = "<div>Hello <span> </span></div>"
    result = ""
    result << "<div><%= I18nTemplate.t(\"Hello\") %> <span> </span></div>"

    subject

    assert_equal(result, document.source)
  end


  it "should split phrase with empty span if 'n' custom attribute given" do
    @source = "<div>Hello <span data-i18n=\"n\"> </span> here</div>"
    result = ""
    result << "<div>"
    result << "<%= I18nTemplate.t(\"Hello\") %>"
    result << " <span data-i18n=\"n\"> </span>"
    result << " <%= I18nTemplate.t(\"here\") %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should self_close_tag" do
    @source = "<div>Hello<br />World</div>"
    result = ""
    result << "<div>"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['[1/]'] = capture do -%><br /><%- end -%>"
    result << "<%= I18nTemplate.t(\"Hello[1/]World\", i18n_values) %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should several_self_close_tag" do
    @source = "<div>Hello<br />World<input type=\"button\"/>Today</div>"
    result = ""
    result << "<div>"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['[1/]'] = capture do -%><br /><%- end -%>"
    result << "<%- i18n_values['[2/]'] = capture do -%><input type=\"button\"/><%- end -%>"
    result << "<%= I18nTemplate.t(\"Hello[1/]World[2/]Today\", i18n_values) %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should self_close_tag_at_the_end" do
    @source = "<div>Hello<br /></div>"
    result = ""
    result << "<div>"
    result << "<%- i18n_values = {} -%>"
    result << "<%- i18n_values['[1/]'] = capture do -%><br /><%- end -%>"
    result << "<%= I18nTemplate.t(\"Hello[1/]\", i18n_values) %>"
    result << "</div>"

    subject

    assert_equal(result, document.source)
  end

  it "should select_tag" do
    @source =<<-DATA
<div>
<select name="company">
  <option value="mercedes">Mercedes</option>
  <option value="audi">Audi</option>
</select>
</div>
DATA

    subject

    assert_equal(<<-DATA, document.source)
<div>
<select name="company">
  <option value="mercedes"><%= I18nTemplate.t("Mercedes") %></option>
  <option value="audi"><%= I18nTemplate.t("Audi") %></option>
</select>
</div>
DATA
  end

  it "should nbsp_html_entity" do
    @source =<<-DATA
<div style="clear:both">&nbsp;  &#169;</div>
DATA

    assert subject

    assert_equal(0, document.errors.size)
    assert_equal(<<-DATA, document.source)
<div style="clear:both">&nbsp;  &#169;</div>
DATA
  end

  it "should extra_open_tag" do
    @source =<<-DATA
<div>
  <h2>hello</h2>
  <p>
DATA

    assert subject

    assert_equal(0, document.errors.size)
    assert_equal(<<-DATA, document.source)
<div>
  <h2><%= I18nTemplate.t("hello") %></h2>
  <p>
DATA
  end

  it "should extra_close_tag" do
    @source =<<-DATA
<div>
  <h2>hello</h2>
</div>
</div>
DATA

    assert_equal(false, subject)

    assert_equal(1, document.errors.size)
    assert_equal(<<-DATA, document.source)
<div>
  <h2>hello</h2>
</div>
</div>
DATA
  end

  it "should extra_close_tag_innen" do
    @source =<<-DATA
<div>
  <h2>hello</h2>
  </p>
</div>
DATA

    assert_equal(false, subject)

    assert_equal(1, document.errors.size)
    assert_equal(<<-DATA, document.source)
<div>
  <h2>hello</h2>
  </p>
</div>
DATA
  end


  it "should i18n source with 'if/else/end' block" do
    @source =<<-DATA
<div>
  <%- if total_price -%>
    <div>Total price: <span><%= total_price %></span></div>
  <%- else -%>
    <div>Total price: N/A</div>
  <%- end -%>
</div>
    DATA

    assert_equal(true, subject)

    assert_equal(<<-DATA, document.source)
<div>
  <%- if total_price -%>
    <div><%- i18n_values = {} -%><%- i18n_values['[1]'] = capture do -%><span><%- end -%><%- i18n_values['{1}'] = capture do -%><%= total_price %><%- end -%><%- i18n_values['[/1]'] = capture do -%></span><%- end -%><%= I18nTemplate.t(\"Total price: [1]{1}[/1]\", i18n_values) %></div>
  <%- else -%>
    <div><%= I18nTemplate.t("Total price: N/A") %></div>
  <%- end -%>
</div>
    DATA
  end

  it "should properly use 'n' and 'i' attributes" do
    @source =<<-DATA
<div>
  <span data-i18n="n">Welcome!</span>
  <span data-i18n="i">Ignore Me</span>
</div>
    DATA

    assert_equal(true, subject)

    assert_equal(<<-DATA, document.source)
<div>
  <span data-i18n="n"><%= I18nTemplate.t("Welcome!") %></span>
  <span data-i18n="i">Ignore Me</span>
</div>
DATA
  end

  it "should properly i18n source with nested div" do
    @source =<<-DATA
<div id="level1">
  Hello, <%= user_name %>!
  <div id="level2">Welcome to our site</div>
</div>
    DATA

    assert_equal(true, subject)

    assert_equal(<<-DATA, document.source)
<div id="level1">
  <%- i18n_values = {} -%><%- i18n_values['{1}'] = capture do -%><%= user_name %><%- end -%><%= I18nTemplate.t("Hello, {1}!", i18n_values) %>
  <div id="level2"><%= I18nTemplate.t("Welcome to our site") %></div>
</div>
DATA

  end

  it "should i18n complex source with spans" do
    @source =<<-DATA
<div>
  inner <span>This is <span>one</span> message </span> outer
</div>
    DATA

    assert_equal(true, subject)

    assert_equal(<<-DATA, document.source)
<div>
  <%- i18n_values = {} -%><%- i18n_values['[1]'] = capture do -%><span><%- end -%><%- i18n_values['[2]'] = capture do -%><span><%- end -%><%- i18n_values['[/2]'] = capture do -%></span><%- end -%><%- i18n_values['[/1]'] = capture do -%></span><%- end -%><%= I18nTemplate.t("inner [1]This is [2]one[/2] message [/1] outer", i18n_values) %>
</div>
DATA
  end

  it "should i18n inline with erb scriplet" do
    @source =<<-DATA
<div>
  This is your <b><%= user.score %></b> score!
</div>
    DATA

    assert_equal(true, subject)

    assert_equal(<<-DATA, document.source)
<div>
  <%- i18n_values = {} -%><%- i18n_values['[1]'] = capture do -%><b><%- end -%><%- i18n_values['{1}'] = capture do -%><%= user.score %><%- end -%><%- i18n_values['[/1]'] = capture do -%></b><%- end -%><%= I18nTemplate.t("This is your [1]{1}[/1] score!", i18n_values) %>
</div>
DATA
  end

  it "should i18n erb scriplets in order" do
    @source =<<-DATA
<div>
  <%- username = @user.name -%>
  Hello <b><%= username %></b>!
</div>
    DATA

    assert_equal(true, subject)

    assert_equal(<<-DATA, document.source)
<div>
  <%- username = @user.name -%>
  <%- i18n_values = {} -%><%- i18n_values['[1]'] = capture do -%><b><%- end -%><%- i18n_values['{1}'] = capture do -%><%= username %><%- end -%><%- i18n_values['[/1]'] = capture do -%></b><%- end -%><%= I18nTemplate.t("Hello [1]{1}[/1]!", i18n_values) %>
</div>
DATA
  end

  it "should i18n phrase with embed wotlds and scriplet" do
    @source =<<-DATA
<p>Welcome <i>Mr.</i> <%= current_user.name %> to <em>Your Blog</em></p>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<p><%- i18n_values = {} -%><%- i18n_values['[1]'] = capture do -%><i><%- end -%><%- i18n_values['[/1]'] = capture do -%></i><%- end -%><%- i18n_values['{1}'] = capture do -%><%= current_user.name %><%- end -%><%- i18n_values['[2]'] = capture do -%><em><%- end -%><%- i18n_values['[/2]'] = capture do -%></em><%- end -%><%= I18nTemplate.t(\"Welcome [1]Mr.[/1] {1} to [2]Your Blog[/2]\", i18n_values) %></p>
    DATA
  end

  it "should replace br tag" do
    @source =<<-DATA
<label for="user_address">Address: <br />(required)</label>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<label for="user_address"><%- i18n_values = {} -%><%- i18n_values['[1/]'] = capture do -%><br /><%- end -%><%= I18nTemplate.t("Address: [1/](required)", i18n_values) %></label>
    DATA
  end

  it "should skip JS scriplet" do
    @source =<<-DATA
<div>
  <span><span>Doubled Welcome!</span></span>
  <script>alert("Hello!")</script>
</div>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<div>
  <span><span><%= I18nTemplate.t(\"Doubled Welcome!\") %></span></span>
  <script>alert("Hello!")</script>
</div>
    DATA
  end

  it "should consider 'n' for doubled span" do
    @source =<<-DATA
<div>
  <span><span data-i18n="n">Greeting:</span></span> <span data-i18n="n">How are you?</span>
</div>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<div>
  <span><span data-i18n="n"><%= I18nTemplate.t("Greeting:") %></span></span> <span data-i18n="n"><%= I18nTemplate.t("How are you?") %></span>
</div>
    DATA
  end

  it "should consider 'n' for doubled span with one custom attr" do
    @source =<<-DATA
<div>
  <span><span data-i18n="n">Greeting:</span></span> <span>How are you?</span>
</div>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<div>
  <span><span data-i18n="n"><%= I18nTemplate.t("Greeting:") %></span></span> <span><%= I18nTemplate.t("How are you?") %></span>
</div>
    DATA
  end


  it "should i18n table" do
    @source =<<-DATA
<table>
  <tr>
    <th>First Name</th>
    <td><%= first_name %></td>
  </tr>
  <tr>
    <th>Last Name</th>
    <td><%= last_name %></td>
  </tr>
</table>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<table>
  <tr>
    <th><%= I18nTemplate.t("First Name") %></th>
    <td><%= first_name %></td>
  </tr>
  <tr>
    <th><%= I18nTemplate.t("Last Name") %></th>
    <td><%= last_name %></td>
  </tr>
</table>
    DATA
  end

  it "should NOT translate inline erb fold inside html block element" do
    @source =<<-DATA
<div>
Hi <span class="<%= @class_name %>"><%= username %></span>!
</div>
  DATA

    subject

    assert_equal(<<-DATA, document.source)
<div>
<%- i18n_values = {} -%><%- i18n_values['[1]'] = capture do -%><span class="<%= @class_name %>"><%- end -%><%- i18n_values['{1}'] = capture do -%><%= username %><%- end -%><%- i18n_values['[/1]'] = capture do -%></span><%- end -%><%= I18nTemplate.t("Hi [1]{1}[/1]!", i18n_values) %>
</div>
    DATA
  end

  it "should NOT translate block erb fold" do
    @source =<<-DATA
<div>  Congrats! <%- @before = Time.now -%></div>
  DATA

    subject

    assert_equal(<<-DATA, document.source)
<div>  <%= I18nTemplate.t("Congrats!") %> <%- @before = Time.now -%></div>
    DATA
  end

  it "should NOT translate erb comments" do
    @source =<<-DATA
<div>Congrats! <%# user.name %></div>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<div><%= I18nTemplate.t("Congrats!") %> <%# user.name %></div>
    DATA
  end

  it "should NOT translate content with only erb evals" do
    @source =<<-DATA
<%= link_to 'Show', @post %> 
<%= link_to 'Back', posts_path %>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<%= link_to I18nTemplate.t("Show"), @post %> 
<%= link_to I18nTemplate.t("Back"), posts_path %>
    DATA
  end

  it "should NOT translate content in javascript_tag block" do
    @source =<<-DATA
<%= javascript_tag :defer => 'defer' do %>
  $(document).ready(function(){
    GoogleCollections.inlideEdit();
  });
<% end %>
<span>Hello</span>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<%= javascript_tag :defer => 'defer' do %>
  $(document).ready(function(){
    GoogleCollections.inlideEdit();
  });
<% end %>
<span><%= I18nTemplate.t("Hello") %></span>
    DATA
  end

  it "should NOT translate content in javascript_tag block wrapped with content_for block" do
    @source =<<-DATA
<%= content_for :head do -%>
  <%= javascript_tag  do %>
    $(document).ready(function(){
      GoogleCollections.inlideEdit();
    });
  <% end %>
<%- end -%>
<span>Hello</span>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<%= content_for :head do -%>
  <%= javascript_tag  do %>
    $(document).ready(function(){
      GoogleCollections.inlideEdit();
    });
  <% end %>
<%- end -%>
<span><%= I18nTemplate.t("Hello") %></span>
    DATA
  end

  it "should NOT translate content with many block wrappers" do
    @source =<<-DATA
<%= content_for :head do %>
  <%= javascript_tag do %>
    $(document).ready(function(){
    GoogleCollections.autoName("project");
    });
  <% end %>
<% end %>

<h2>New Project</h2>

<%= form_for :project, :url => projects_path, :html => { :class => :form } do |f| -%>
  <%= render :partial => "form", :locals => {:f => f} %>
<% end -%>

<% content_for :sidebar, render(:partial => 'sidebar') -%>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<%= content_for :head do %>
  <%= javascript_tag do %>
    $(document).ready(function(){
    GoogleCollections.autoName("project");
    });
  <% end %>
<% end %>

<h2><%= I18nTemplate.t("New Project") %></h2>

<%= form_for :project, :url => projects_path, :html => { :class => :form } do |f| -%>
  <%= render :partial => "form", :locals => {:f => f} %>
<% end -%>

<% content_for :sidebar, render(:partial => 'sidebar') -%>
    DATA
  end

  it "should NOT translate content in eval erb block" do
    @source =<<-DATA
<%= content_for :head do %>
  message
<% end %>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<%= content_for :head do %>
  message
<% end %>
    DATA
  end

  it "should translate content in non-eval erb block" do
    @source =<<-DATA
<% content_for :head do %>
  message
<% end %>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<% content_for :head do %>
  <%= I18nTemplate.t("message") %>
<% end %>
    DATA
  end

  it "should translate link_to helper with single quote" do
    @source =<<-DATA
<%= link_to "Jack' Home", home_path %>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<%= link_to I18nTemplate.t("Jack' Home"), home_path %>
    DATA
  end

  it "should translate link_to helper with double quote" do
    @source =<<-DATA
<%= link_to '"My" Home', home_path %>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<%= link_to I18nTemplate.t("&quot;My&quot; Home"), home_path %>
    DATA
  end

  it "should translate link_to helper with parentheses" do
    @source =<<-DATA
<%= link_to ( 'Home', home_path ) %>
    DATA

    subject

    assert_equal(<<-DATA, document.source)
<%= link_to ( I18nTemplate.t("Home"), home_path ) %>
    DATA
  end
end
