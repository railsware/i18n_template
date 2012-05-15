# encoding: UTF-8

require "i18n_template/version"
require "i18n_template/railtie"

module I18nTemplate
  autoload :Document,    'i18n_template/document'
  autoload :Handler,     'i18n_template/handler'
  autoload :Runner,      'i18n_template/runner'

  module Translator
    autoload :I18n, 'i18n_template/translator/i18n'
  end

  FOLD_TYPE_PATTERN_MAPPING = [
    [ 'html_doctype',   /<!DOCTYPE.+?>/m                ],
    [ 'html_script',    /<script[^>]*?>.+?<\/script>/m  ],
    [ 'html_style',     /<style[^>]*?>.+?<\/style>/m    ],
    [ 'html_comment',   /<!--.+?-->/m                   ],
    [ 'erb_do',         /<%=\s*(.+)\s+do\s*-?%>/        ],
    [ 'erb_end',        /<%-?\s*end\s*-?%>/m            ],
    [ 'erb_expression', /<%=(.*?)%>/m                   ],
    [ 'erb_comment',    /<%#(.*?)%>/m                   ],
    [ 'erb_code',       /<%[^=](.*?)%>/m                ]
  ].freeze

  FOLD_START = [0x2264].pack("U*").freeze

  FOLD_END = [0x2265].pack("U*").freeze

  FOLD_PATTERN = /#{FOLD_START}(\d+):(\w+)#{FOLD_END}/.freeze

  TAG_PATTERN = /<(\/)?(\w+(:[\w_-]+)?)/.freeze

  I18N_ATTR_PATTERN = /data-i18n=(?:"|')(i|n|s)(?:"|')/.freeze

  HTML_ENTITY_PATTERN = /&(#\d+|\w+);/

  INLINE_TAGS = %w[
    a abbr acronym b bdo big br cite code dfn em i img input kbd label q samp
    small span strong sub sup textarea tt var button del ins map object
  ]

  SELF_CLOSE_TAGS = %w[area base basefont br hr input img link meta]

  ESCAPE_MAPPING = {
    '"' => '[quot]',
    '[' => '[lsb]',
    ']' => '[rsb]',
    '{' => '[lcb]',
    '}' => '[rcb]',
  }

  UNESCAPE_MAPPING = ESCAPE_MAPPING.invert

  ESCAPE_REGEXP = Regexp.new(
    ESCAPE_MAPPING.keys.map { |key| Regexp.escape(key) }.join('|') )

  UNESCAPE_REGEXP = Regexp.new(
    UNESCAPE_MAPPING.keys.map { |key| Regexp.escape(key) }.join('|')
  )

  INTERPOLATE_REGEXP = /(\[\d+\]|\[\/\d+\]|\[\d+\/\]|\{\d+\})/.freeze

  RAILS_HELPERS = %w[
    button_to 
    field_set_tag
    label_tag
    link_to 
    link_to_remote
    submit_tag 
  ]

  RAILS_HELPER_PATTERN = /(#{RAILS_HELPERS.join('|')})([\s\(]*)(?:"([\w\s\/']*)"|'([\w\s\/"]*)')/


  class << self
    attr_accessor :debug

    def runners
      @runners ||= []
    end

    def extractors
      @extractors ||= []
    end

    def translator
     @translator ||= I18nTemplate::Translator::I18n
    end

    def register_translator(translator)
      @translator = translator
    end

    def escape!(string)
      string.gsub!(ESCAPE_REGEXP) do |char| 
        ESCAPE_MAPPING.fetch(char, char)
      end
    end

    def unescape!(string)
      string.gsub!(UNESCAPE_REGEXP) do |char| 
        UNESCAPE_MAPPING.fetch(char, char)
      end
    end

    def interpolate!(string, values)
      string.gsub!(INTERPOLATE_REGEXP) do |key|
        values[key]
      end
    end

    def escape(string)
      string = string.dup
      escape!(string)
      string
    end

    def unescape(string)
      string = string.dup
      unescape!(string)
      string
    end

    def interpolate(string, values)
      string = string.dup
      interpolate!(string, values)
      string
    end

    def translate(key, values = {})
      phrase = (translator.call(key) || key).dup

      interpolate!(phrase, values)

      unescape!(phrase)

      phrase.respond_to?(:html_safe) ? phrase.html_safe : phrase
    end

    alias_method :t, :translate
  end
end
