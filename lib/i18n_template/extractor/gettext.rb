module I18nTemplate
  module Extractor
    #
    # Extract phrases to gettext format. E.g. pot/po files
    #
    # Extractor creates and updates:
    #  * {po_root}/{textdomain}.pot
    #  * {pr_root}/{lang}/{textdomain}.po
    class Gettext < Base

      I18nTemplate.extractors << self

      class << self
        def format
          'gettext'
        end

        def default_options
          super.merge({
            :po_root    => 'po',
            :textdomain => 'phrases'
          })
        end
      end

      def initialize(options)
        super(options)

        @version = 'version 0.0.1'
        @pot_file = File.join(@options[:po_root], "#{@options[:textdomain]}.pot")
        @pot_file_tmp = "#{@pot_file}.tmp"
      end

      def call(paths)
        # ensure root directory exists
        FileUtils.mkdir_p(@options[:po_root])

        # generate new temporary pot file
        File.open(@pot_file_tmp, "w") do |f|
          f.puts generate_pot_header
          f.puts ""
          f.puts generate_pot_body(paths)
        end

        # merge pot file
        log("Merging #{@pot_file}")
        if File.exist?(@pot_file)
          merge_po_files(@pot_file, @pot_file_tmp)
        else
          FileUtils.cp(@pot_file_tmp, @pot_file)
        end

        # merge po files
        Dir.glob("#{@options[:po_root]}/*/#{@options[:textdomain]}.po") do |po_file|
          log("Merging #{po_file}")
          concate_po_files(po_file, @pot_file_tmp)
        end

        # remove temporary pot file
        FileUtils.rm(@pot_file_tmp)
      end

      protected

      def generate_pot_header
        time = Time.now.strftime("%Y-%m-%d %H:%M")
        off = Time.now.utc_offset
        sign = off <= 0 ? '-' : '+'
        time += sprintf('%s%02d%02d', sign, *(off.abs / 60).divmod(60))

        <<-TITLE
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"POT-Creation-Date: #{time}\\n"
"PO-Revision-Date: #{time}\\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL@li.org>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"
TITLE
      end

      def generate_pot_body(paths)
        sources = {}

        paths.each do |path|
          phrases = extract_phrases(path)
          phrases.each do |phrase|
            sources[phrase] ||= []
            sources[phrase] << path 
          end
        end

        log("Extracted #{sources.keys.size} phrases")

        data = ""
        sources.sort.each do |phrase, paths|
          data << "# #{paths.join(",")}\n"
          data << "msgid #{phrase.inspect}\n"
          data << "msgstr \"\"\n"
          data << "\n"
        end
        data
      end

      def concate_po_files(def_po, ref_po)
        command = "msgcat --output-file #{def_po} --use-first #{def_po} #{ref_po}"
        system(command) or raise RuntimeError, "can't run #{command.inspect}"
      end

      def merge_po_files(def_po, ref_po)
        command = "msgmerge --quiet --update #{def_po} #{ref_po}"
        system(command) or raise RuntimeError, "can't run #{command.inspect}"
      end

    end
  end
end
