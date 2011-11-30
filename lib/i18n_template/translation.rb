module I18nTemplate
  module Translation
    class << self
      CLOSE_TAG_BEGIN_PATTERN = /
        (?=<\/)(.*?)$     # match any string that begins with <\/ characters as 1 
      /x.freeze

      WRAPPER_OR_VARIABLE_PATTERN = /(
        \{\}              # empty braces
        |                 # or
          \{([^\}]+)\}    # match any data except close brace in braces as 2
        |                 # or
          \[(\/?)(\d+)\]  # optional match back-slash character as 3 and digits as 4 in brackets
      )/x.freeze

      T9N_CLEANUP_PATTERN = /\s+(i18n_wrapper="\d+"|i18n="\w")/x.freeze

      # translate phrase and replace placeholders and variables
      def translate(key, wrappers, vars)
        # map each wrapper to open and close tag
        # e.g '<a><b><c>bla</d></e>' -> [ '<a><b><c>bla', '</d></e>' ]
        wrappers = wrappers.collect do |w|
          w =~ CLOSE_TAG_BEGIN_PATTERN ? [w[0, w.size-$1.size], $1] : ['', '']
        end

        phrase = (I18nTemplate.translator.call(key) || key).dup

        # replaces {variable name} or [digits] or [\digits]
        # with wrappers and variables
        phrase.gsub!(WRAPPER_OR_VARIABLE_PATTERN) do |s|
          case s[0, 1]
          when '{' then s == '{}' ? vars[''] : vars[$2]
          when '[' then (wrappers[$4.to_i] || [])['/' == $3 ? 1 : 0]
          end
        end

        # replace nl with break line
        phrase.gsub!("[nl]", "<br />")

        # replace unescaped characters
        phrase.gsub!("[lsb]", "[")
        phrase.gsub!("[rsb]", "]")
        phrase.gsub!("[lcb]", "{")
        phrase.gsub!("[rcb]", "}")
        phrase.gsub!("[ns]",  "#")

        # remove i18n attributes. E.g:
        # i18n_wrapper='100'
        # i18n="i"
        phrase.gsub!(T9N_CLEANUP_PATTERN, '')

        if phrase.respond_to?(:html_safe)
          # return html_safe phrase
          phrase.html_safe
        else
          # return pure string
          phrase
        end
      end
    end
  end
end
