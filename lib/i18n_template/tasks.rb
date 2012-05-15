namespace :i18n_template do
  desc "Inspect template"
  task :inspect_template, :name do |t, args|
    path = Rails.root + 'app' + 'views' + "#{args[:name]}.html.erb"

    abort "Can't open #{path}" unless File.exists?(path)
    document = ::I18nTemplate::Document.new(File.read(path))

    if document.process!
      puts "#"*80
      puts "# Source"
      puts "#"*80
      puts document.source

      puts "#"*80
      puts "# Keys"
      puts "#"*80
      document.keys.each do |key|
        puts key.inspect
      end
    else
      puts "#"*80
      puts "# Errors"
      puts "#"*80
      document.errors.each do |message|
        puts message
      end
    end
  end

  desc "show i18n keys"
  task :show_keys do
    glob = Rails.root + 'app' + 'views' + '**' + '*.html.erb'
    paths = Dir[glob]

    paths.each do |path|
      document = ::I18nTemplate::Document.new(File.read(path))

      if document.process!
        puts "[OK] #{path}: #{document.keys.size} keys"
        document.keys.each do |key|
          puts key
        end
      else
        puts "[ERR] #{path}: #{document.errors.size} errors"
        document.errors.each { |message|
          puts message
        }
      end
    end
  end

  desc "update i18n keys"
  task :update_keys do
    locales_glob = Rails.root + 'config' + 'locales' + '*.yml'
    templates_glob = Rails.root + 'app' + 'views' + '**' + '*.html.erb'

    locales = Dir[locales_glob]
    abort "Can't found any locale with #{locales_glob}" if locales.empty?
    puts "Found #{locales.size} locales"

    templates = Dir[templates_glob]
    abort "Can't found any template with #{templates_glob}" if templates.empty?
    puts "Found #{templates.size} templates"

    keys = []

    templates.each do |path|
      document = ::I18nTemplate::Document.new(File.read(path))

      if document.process!
        keys += document.keys
      else
        $stderr.puts "[ERR] #{path}: #{document.errors.size} errors"
        document.errors.each { |message|
          $stderr.puts message
        }
      end
    end

    keys.uniq!
    keys.each { |key| key.force_encoding('UTF-8') if key.respond_to?(:force_encoding) }
    keys.sort!

    puts "Found #{keys.size} keys"

    locales.each do | locale_path|
      locale = File.basename(locale_path, '.yml')

      puts "Updating keys in #{locale_path}"
      data = YAML.load_file(locale_path)

      if data.key?(locale)
        hash = data[locale]
        keys.each do |key|
          hash[key] = nil unless hash.key?(key) 
        end
        File.open(locale_path, "w") { |f| f <<  data.to_yaml }
      else
        puts "Can't found #{locale} key"
      end
    end

  end

  desc "translate i18n keys"
  task :translate_keys do
    require 'net/http'
    require 'cgi'
    require 'yaml'
    require 'json'

    def i18n_template_translate(key, lang)
      host = "mymemory.translated.net"
      path = "/api/get"
      path << "?"
      path << "q=#{CGI.escape(key)}"
      path << "&"
      path << "langpair=en|#{lang}"

      response = Net::HTTP.get(host, path)
      body = JSON.parse(response)

      value = body['responseData']['translatedText']

      puts "Translated #{key.inspect} as #{value.inspect}"

      value.gsub!(/\[\/\s+(\d+)\]/) { "[/#{$1}]" }
      value.gsub!(/\[(\d+)\s+\/\]/) { "[#{$1}/]" }

      value

    rescue => e
      $stderr.puts e.inspect
      nil
    end

    locales_glob = Rails.root + 'config' + 'locales' + '*.yml'
    locales = Dir[locales_glob]
    abort "Can't found any locale with #{locales_glob}" if locales.empty?
    puts "Found #{locales.size} locales"

    locales.each do | locale_path|
      locale = File.basename(locale_path, '.yml')
      next if locale == 'en'

      puts "Translating keys in #{locale_path}"
      data = YAML.load_file(locale_path)

      if data.key?(locale)
        hash = data[locale]
        hash.each do |key, value|
          next unless value.nil?
          hash[key] = i18n_template_translate(key, locale)
        end
        File.open(locale_path, "w") { |f| f <<  data.to_yaml }
      else
        puts "Can't found #{locale} key"
      end
    end
  end

end
