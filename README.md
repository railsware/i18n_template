# I18nTemplate

## Main Feature

Just compare regulare rails view internationalization:

    <html>
      <body>
        <% current_year = Time.now.year %>
        <span><%= t('hello') %></span>
        <h2><%= t('Dashboard') </h2>
        <div><%= t('Posts count:') %><%= current_user.posts.count %></div>
        <div><%= t('Click') %><a href="#"><%= t('here') %></a></div>
        ...
      </body>
    </html>

with i18n template internationalization:

    <html>
      <body>
        <% current_year = Time.now.year %>
        <span i18n="p">hello</span>
        <h2>Dashboard</h2>
        <div>Posts count: <%= current_user.posts.count %></div>
        <div>Click<a href="#">here</a></div>
        ...
      </body>
    </html>

Nice?

## How it Works

It convert *on the fly* regular erb template to another erb template. For above example this is something like:

    <html>
      <body>
        <% current_year = Time.now.year %>
        <span>
          <%- i18n_variables = {}; i18n_wrappers = [] -%>
          <%= ::I18nTemplate::Translation.translate("hello", i18n_wrappers, i18n_variables) %>
        </span>
        <h2>
          <%- i18n_variables = {}; i18n_wrappers = [] -%>
          <%= ::I18nTemplate::Translation.translate("Dashboard", i18n_wrappers, i18n_variables) %>
         </h2>
        <div>
          <%- i18n_variables = {}; i18n_wrappers = [] -%>
          <%- i18n_variables['current user posts count'] = capture do -%>
            <%= current_user.posts.count %>
          <%- end -%>
          <%= ::I18nTemplate::Translation.translate("Posts count: {current user posts count}",
              i18n_wrappers, i18n_variables) %>
        </div>
        <div>
          <%- i18n_variables = {}; i18n_wrappers = [] -%>
          <%- i18n_wrappers[1] = capture do -%>
            <a href="#" i18n_wrapper="1">
              <%- i18n_variables = {}; i18n_wrappers = [] -%>
              <%= ::I18nTemplate::Translation.translate("here", i18n_wrappers, i18n_variables) %>
            </a>
          <%- end -%>
          <%= ::I18nTemplate::Translation.translate("Click[1]here[/1]", i18n_wrappers, i18n_variables) %>
         </div>
      </body>
    </html>

Translation phrases (keys):

* _hello_
* _Dashboard_
* _Posts count: {current user posts count}_
* _Click[1]here[/1]_

## Description

I18nTemplate is made to extract phrases and translate html/xhtml/xml document or erb templates.
Currently the it can work with (x)html documents.
Translation is done by modify the original template (on the fly) to be translated on erb execution time.

## Semantics

The engine is leveraging the HTML document semantics.
As we know HTML document element can contain : block elements and/or inline elements.
The engine has the following parsing rules, based on what kind of children a parent element contains:

* block element containing only block elements - is named a parent element, and is ignored by the engine;
* block element containing only inline elements - is named phrase, while every inline element is named a word;
* inline element containing other inline elements - is also a word;
* any other variation - is considered a broken element, which should be one of there above.

### Markup

Additionally for the sake of best practices and optimiztion the following rules take place:

* the following elements as considered block elements by the engine 
 * usual block : `blockquote p div h1 h2 h3 h4 h5 h6 li dd dt`
 * inline elements : `td th a legend label title caption option optgroup button`
* the following elements, and their content, will be ignored by the engine:
 * html elements: `select style script` 
 * non-breaking space: `&nbsp;` 
 * erb scriptlets: `<% <%=`
 * html comments: `<!-- -->`
 * xhtml doctype: `<!DOCTYPE`
* additional best practices are added to translate content inside such tags

In order to fix a broken elements next elements/attributes can be added to the html document to resolve engine misunderstanding:

* `<i18n>content</i18n>` - mark invisible for parser content for internationalization
* `<... i18n="i" ...>content<...>`  - (ignore) ignore element content internationalization
* `<... i18n="p" ...>content<...>`  - (phrase) explicitly enable content internationalization
* `<... i18n="s" ...>content<...>`  - (subphrase) mark element content as sub-phrase for parent element phrase

## Translation

### Brackets

    [1]Hello World[/1]

### Braces

Example

    Hello { user name }

* `<%= @user_name %>`  as `{user name}`
* `<%= user_name %>`  as `{user name}`
* `<%= @post.comments.count %>`  as `{post comments count}`

## Using with Rails (2.3.x 3.x.x)

    $ gem install i18n_template

    require 'i18n_template'

    ActionView::Template.register_template_handler(:erb, I18nTemplate::Handler.new)

### Set another phrase translator:

    I18nTemplate.phrase_translator = lambda { |phrase| Google.translate(phrase) }

### More template internationalize control

Assume we don't want to internationalize admin view templates.

    class MyI18nTemplateHandler < I18nTemplate::Handler
      def internationalize?(template)
        if template.respond_to?(:path)
          path =~ /^admin/ ? false : true
        else
          true
        end
      end
    end

    ActionView::Template.register_template_handler(:erb, MyI18nTemplateHandler.new)

## Testing

### Setup

    $ rvm alias create rails23_r187 ruby-1.8.7
    $ rvm alias create rails30_r193 ruby-1.9.3
    $ rvm alias create rails31_r193 ruby-1.9.3

    $ gem install multiversion
    $ multiversion all bundle install

### Run

Against all versions:

    $ multiversion all exec testrb test/*_test.rb

Against specific versions:

    $ multiversion rails30_r193,rails31_r193 exec testrb test/*_test.rb


## Extract phrases

    $ i18n_template --help
    extract_phrases - extract phrases for translations
        --format plain|gettext|yaml  translation format (default gettext)
        --po-root PO ROOT            root directly for po files (default po)
        --glob GLOB                  template files glob (default app/views/**/*.{erb,rhtml})
        --textdomain TEXTDOMAIN      gettext textdomain (default phrases)
        --output-file FILE           output file (default template_phrases.txt)
        --locales-root DIRECTORY     locales directory (default config/locales)

### Plain format

    $ i18n_template extract_phrases --format plain --output-file /tmp/phrases.txt

### Yaml format

    $ i18n_template extract_phrases --format yaml

    $ cat config/locales/phrases.yml
    en:
      Hello {user name}, {message}: 
      '[1]First name[/1] : {profile first name}': 
      '[1]Last name[/1] : {profile last name}': 
      '[1]Email[/1] : {account email}': 
      Copyright {current year}. All rights reserved.: 

### Gettext format

    $ i18n_template extract_phrases \
      --textdomain myapp \
      --glob app/views/**/*.erb \
      --glob lib/view/**/*.erb

    $ tree --dirsfirst po
    po
    ├── de
    │   └── myapp.po
    └── myapp.pot

    $ cat po/phrases.pot
    # SOME DESCRIPTIVE TITLE.
    # Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
    # This file is distributed under the same license as the PACKAGE package.
    # FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
    #
    msgid ""
    msgstr ""
    "Project-Id-Version: PACKAGE VERSION\n"
    "POT-Creation-Date: 2011-11-28 15:38+0200\n"
    "PO-Revision-Date: 2011-11-25 21:27+0200\n"
    "Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
    "Language-Team: LANGUAGE <LL@li.org>\n"
    "Language: \n"
    "MIME-Version: 1.0\n"
    "Content-Type: text/plain; charset=UTF-8\n"
    "Content-Transfer-Encoding: 8bit\n"
    "Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\n"

    # app/views/_footer.html.erb
    msgid "Copyright {current year}. All rights reserved."
    msgstr ""

    # app/views/greeting.html.erb
    msgid "Hello {user name}, {message}"
    msgstr ""

## References

* [multiversion](https://github.com/railsware/multiversion)
