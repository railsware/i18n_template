require 'abstract_unit'
require 'yaml'

class FixturesRenderingTest < ActionView::TestCase
  include I18nTestCaseHelper

  FIXTURES = Dir['test/fixtures/*.yml'].sort.map { |file_name|
    name = File.basename(file_name, '.yml')
    begin
      data = YAML.load_file(file_name)
    rescue => e
      puts "Error occurs in fixture: #{file_name}"
      raise e
    end
    [ name, data ]
  }

  FIXTURES.each do |name, data|
    define_method("test_#{name}") do
      %w(template assigns locals phrases translations rendered).each do |key|
        data[key] or raise ArgumentError, "Please specify '#{key}' key"
      end

      data['assigns'].each do |key, val|
        instance_variable_set("@#{key}", val)
      end

      data['phrases'].size.times do |i|
        add_translation(data['phrases'][i], data['translations'][i]) 
      end

      document = I18nTemplate::Document.new(data['template'])
      document.preprocess!
      assert_equal(data['phrases'], document.phrases)

      render({
        :inline => data['template'],
        :locals => data['locals'],
        :type => :erb
      })

      assert_equal(data['rendered'], rendered)
    end
  end

end
