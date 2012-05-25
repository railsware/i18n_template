# I18nTemplate

On the fly internationalization of HTML/ERuby Rails templates.

Work with Rails:

* v2.3.x
* v3.0.x
* v3.1.x
* v3.2.x

## Very quick start

Add to Gemfile:

    gem "i18n_template"

Install gem:

    $ bundle install

Check new rake tasks:

    $ rake -T i18n_template
    rake i18n_template:update_keys             # update i18n keys
    rake i18n_template:translate_keys          # translate i18n keys
    rake i18n_template:show_keys               # show i18n keys
    rake i18n_template:inspect_template[name]  # inspect template

Ensure you have at least one locale file e.g. `config/locales/en.yml` 

Now you can internationalize and translate ALL your templates ONLY in 2 steps!

    $ rake i18n_template:update_keys
    $ rake i18n_template:translate_keys

That's all! Start server and check views in different locales.

## Preface

[Official rails i18n guide](http://guides.rubyonrails.org/i18n.html) explains how we should internationalize views.

For example next template:

    <div>
      Hello <span class="degree">Prof.</span> Jack!
      <p>Today is <b>Monday</b></p>
    </div>

can be internationalized in different ways.

### Using multiple keys

Template:

    <div>
      <%= t('Hello') > <span class="degree"><%= t("Prof.") %></span> <%= t("Jack!") %>
      <p><%= t('Today is') %><b><%= t('Monday')%</b></p>
    </div>

Keys:

    en:
      Hello: Hello
      Prof: 'Prof.'
      Jack: 'Jack!'
      'Today is: 'Today is'
      Monday: Monday

###  Using HTML keys

Template:

    <div>
      <%= key1_html %>
      <p><%= key2_html %></p>
    </div>

Keys:

    en:
      key1_html: Hello <span class="degree">Prof.</span> Jack!
      key2_html: Today is <b>Monday</b>

### Using Interpolations

Template:

    <div>
      <%= t("Hello %{tag1}Prof.%{tag2} Jack!", :tag1 => '<span class="degree">', :tag2 => '</span>') %>
    <p><%=t ("Today is %{tag1}Monday%{tag2}")", :tag1 => "<b>", :tag2 => "</b>" %></p>

Keys:

    en:
      "Hello %{tag1}Prof.%{tag2} Jack!": "hello %{tag1}Prof.%{tag2} Jack!"
      "Today is %{tag1}Monday%{tag2}": "Today is %{tag1}Monday%{tag2}"


But all approaches has disadvantages:

* Cripple template with `<%= t(...) %>`.
* Forces to create unique key for each phrase.
* There is no official tools to extract translation keys.

**But that's sucks**.

## Concept of I18nTemplate

When you have a huge amount of templates you can waste a huge amount of time for internationalization!
But what about to invent something a little bit smarter?.
Let's analyze structure of HTML/ERuby templates first.

### HTML part

As we know each [HTML element](http://en.wikipedia.org/wiki/HTML_element) can be rendered as either *block* or *inline*. Block element can contain another block or inline elements. But inline element can contain only inline elements. Each element can contain *Text*.

Let's define a *Phrase* as combination of text and inline elements located ONLY in one block element.

For example next text:

    <div>
      Hello <span class="degree">Prof.</span> Jack!
      <p>Today is <b>Monday</b></p>
    </div>

has 2 phrases:

* `Hello []Prof.[] Jack!`
* `Today is []Monday[]`

Where `[]` is container for markup separator or wrapper.

### ERuby part

Eruby has next embed patterns:

* `<% ... %>` - a code
* `<%# ... %>` - a comment
* `<%= ... %>` - an expression

Let's treat *erb expression* as inline element and other erb embeds as block.

For example:

    <div>
      <% if current_user %>
        Hello <span class="degree">Prof.</span> <%= current_user.name %>!
      <% end %>
      <p>Today is <b><% Date::DAYNAMES[Date.today.wday] %></b></p>
    </div>

has 2 phrases:

* `Hello []Prof.[] {}`
* `Today is []{}[]`

Where `{}` is container for interpolation with some variable.

## I18nTemplate key semantic

We treat next HTML elements as inline:

    a abbr acronym b bdo big br cite code dfn em i img input kbd label q samp
    small span strong sub sup textarea tt var button del ins map object

So they are possible candidates to be part of phrase. Block elements can't be a part of phrase.

For template like:

    <body>
      <span><span><%= user.name %></span></span> <br />Welcome <i>aboard</i>
    </body>

Complex key looks like `Hello [1][2]{1}[/2][/1] [3/]Welcome [4]aboard[/4]!`

where:

* `[NUMBER]` - is place for begin of wrapper #NUMBER
* `[/NUMBER]` - is place for end of wrapper #NUMBER
* `[NUMBER/]` - is place for self close wrapper #NUMBER
* `{NUMBER}` - is place for variable #NUMBER


Also we escape next characters in key:

    '"' => '[quot]',
    '[' => '[lsb]',
    ']' => '[rsb]',
    '{' => '[lcb]',
    '}' => '[rcb]',

## Examples

So we have two types of keys: simple and complex. 
Simple key it's only key with text e.g. `Hello World`.
Complex key has wrapper and variable placeholders e.g. `[1]Hello[/1] {1}`.

For simple keys transformation is also simple. We just wrap key with `I18nTemplate.t` method:

    <%= I18nTemplate.t("Hello") %>

I case of complex key we generate local container variable `i18n_values` to store 
values for each placeholder in the key. Then we capture actual placeholder value using `capture` helper and store it as key of `i18n_values`. And pass container variable `i18n_values` as second argument to `I18nTemplate.t` method:

    <%- i18n_values = {} -%>
    <%- i18n_values['{1}'] = capture do -%><%= @user.name %><%- end -%>
    <%= I18nTemplate.t("Hello, {1}", i18n_values)

### Double wrapped text


Original template:

    <body>
      <span><span>Hello</span></span>
    </body>

Transformed template:

    <body>
      <span><span><%= I18nTemplate.t("Hello") %</span></span>
    </body>

Keys:

* `Hello`

### Phrase with wrappers and variables

Original template:

    <body>
      <span>
        <b>How do you do</b>, <%= @user.name %>?
      </span>
    </body>

Transformed template:

    <body>
      <span>
        <%- i18n_values = {} -%>
        <%- i18n_values['[1]'] = capture do -%><b><%- end -%>
        <%- i18n_values['[/1]'] = capture do -%></b><%- end -%>
        <%- i18n_values['{1}'] = capture do -%><%= @user.name %><%- end -%>
        <%= I18nTemplate.t("[1]How do you do[/1], {1}", i18n_values)
      </span>
    </body>

Keys:

* `[1]How do you do[/1], {1}`

### Complex case

Original template:

    <body>
      <h2>User listing</h2>
      <% users.each do |user| %>
        <div class="row">
          Username: <i><%= user.name %></i> <br /> 
          <small><%= user.created_at %></small>
        </div>
      <% end %>
      <div>Total: <%= user.size %> users</div>
    </body>

Transformed template:

    <body>
      <h2><%= I18nTemplate.t('User listing') %></h2>
      <% users.each do |user| %>
        <div class="row">
          <%- i18n_values = {} -%>
          <%- i18n_values['[1]'] = capture do -%><i><%- end -%>
          <%- i18n_values['{1}'] = capture do -%><%= user.name %><%- end -%>
          <%- i18n_values['[/1]'] = capture do -%></i><%- end -%>
          <%- i18n_values['[2/]'] = capture do -%><br /><%- end -%>
          <%- i18n_values['[3]'] = capture do -%><small><%- end -%>
          <%- i18n_values['{2}'] = capture do -%><%= user.created_at %><%- end -%>
          <%- i18n_values['[/3]'] = capture do -%></small><%- end -%>
          <%= I18nTemplate.t("Username: [1]{1}[/1] [/2] [3]{2}[/3]", i18n_values) %>
        </div>
      <% end %>
      <%- i18n_values = {} -%>
      <%- i18n_values['{1}'] = capture do -%><%= user.size %><%- end -%>
      <div><%= I18nTemplate.t("Total: {1}", i18n_values) %>
    </body>

Keys:

* `User listing`
* `Username: [1]{1}[/1] [/2] [3]{2}[/3]`
* `Total: {1}`

### Special i18n tag attribute

Sometimes you need to explicit set behavior. You may use custom HTML attribute `data-i18n` (attribute name is valid for HTML5) with next values:

* `i` - (ignore) ignore internationalization for this tag and *all* it descendants (tags and texts).
* `n` - (new phrase) tag treats as block. So it will break phrase and it first inline child or text starts new phrase.
* `s` - (sub phrase) tag treats as inline. So it will not break phrase and it and it children will be part of current phrase

#### Ignore attribute example

Template:

    <h2 data-i18n="i">Welcome <span>aboard</span>!</h2>

Keys: none.

Compiled template:

    <h2 data-i18n="i">Welcome <span>aboard</span>!</h2>

#### New phrase attribute example

Template:

    <div>Hello<div style="display:inline" data-i18n="s">World</div></div>

Keys:

* `Hello [1]World[/1]`

Compiled template:

    <div>
      <%- i18n_values = {} -%>
      <%- i18n_values['[1]'] = capture do -%><div style="display:inline" data-i18n="s"><%- end -%>
      <%- i18n_values['[/1]'] = capture do -%></div><%- end -%>
      <%= I18nTemplate.t("Hello [1]World[/1]", i18n_values) %>
    </div>

### Sub phrase attribute example

Template:

    <div>
      Error: <span>username</span>
      <span data-i18n="n">(required)</span>
    </div>

Keys:

* `Error: [1]username[/1]`
* `(required)`

Compiled template:

    <div>
      <%- i18n_values = {} -%>
      <%- i18n_values['[1]'] = capture do -%><span><%- end -%>
      <%- i18n_values['[/1]'] = capture do -%></span><%- end -%>
      <%= I18nTemplate.t("Error: [1]username[/1]", i18n_values) %>
      <span data-i18n="n"><% I18nTemplate.t("(required)") %></span>
    </div>


### Rules

* Inline element is _new phrase_ if sibling (prev or next) is not a phrase otherwise it's _sub phrase_.
* Text is _new phrase_ if prev sibling is not a phrase otherwise it's _sub phrase_.
* Block element inside inline element breaks current phrase.
* ERuby expression can be part of phrase as variable.
* Another ERuby treats as block elements thus are not part of phrase

## Testing

### Setup

    $ BUNDLE_GEMFILE=Gemfile.rails32 bundle install
    $ BUNDLE_GEMFILE=Gemfile.rails31 bundle install
    $ BUNDLE_GEMFILE=Gemfile.rails30 bundle install
    $ BUNDLE_GEMFILE=Gemfile.rails23 bundle install

### Run

Against all:

    $ BUNDLE_GEMFILE=Gemfile.rails32 bundle exec rake test
    $ BUNDLE_GEMFILE=Gemfile.rails31 bundle exec rake test
    $ BUNDLE_GEMFILE=Gemfile.rails30 bundle exec rake test
    $ BUNDLE_GEMFILE=Gemfile.rails23 bundle exec rake test

Against specific test:

    $ BUNDLE_GEMFILE=Gemfile.rails32 bundle exec ruby test/i18n_template/document_test.rb -n /0001/


## Under the hood

I18nTemplate consists of next parts:

* I18nTemplate::Document - engine for transforming HMLL/ERuby template to i18n Eruby template and extracting i18n keys
* I18nTemplate::Handler - is handler that registerd via railtie as default erb handler for HTML mime type.
* I18nTemplate::Translator - is simple wrapper for interpolation and translation phrases using I18n engine.
* rake tasks - bunch of tasks to extract, update and translate phrases.

### I18nTemplate::Document

It's the most complex thing in library. Current implementation is next:

* Folds all non-html text as special string like `≤0:erb_code≥`
* Build using simple html tokenizer nodes stack and tree of html elements:
 * each html element as Tag node (open, close, self-close)
 * each text as Text and Fold nodes
* Traverse tree in __postorder__ order and mark each node with possible flags:
 * ignore
 * phrase
 * candidate
* Then traverse tree in __preorder__ and take decision for each candidate node (ignore or phrase)
* Then create replace all nodes marked as phrase with Phrase node.
* Then translate rails helpers inside eruby expression folds
* Then iterate each node invoking to_eruby and store it as source.

Thus we have internationalize template and interpolation keys.

### I18nTemplate::Handler

Is simple handler for ActionView that transform original source via I18nTemplate::Document.


### I18nTemplate::Translator

* Translate phrase using standard I18n engine.
* Interpolate `[NUMBER]`, `[/NUMBER]`, `[NUMBER/]`,`{NUMBER}` with actual values.
* Unescape previously escaped characters


## References

* [i18n_template rubydocs](http://rubydoc.info/github/railsware/i18n_template/master/frames)
* [Rails Internationalization API](http://guides.rubyonrails.org/i18n.html)
