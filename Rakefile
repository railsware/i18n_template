require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.verbose = true
  t.pattern = "test/**/*_test.rb"
end

gemfiles = Dir['Gemfile_*'].reject { |filename| filename =~ /\.lock$/ }

namespace :test do
  gemfile_tasks = []

  gemfiles.each do |gemfile|
    gemfile_task_name = gemfile.downcase.gsub('.', '_').to_sym
    gemfile_tasks << gemfile_task_name

    desc "Testing with #{gemfile}"
    task gemfile_task_name do
      puts "##### Testing with #{gemfile}"

      ENV['BUNDLE_GEMFILE'] = gemfile

      system "bundle install --quiet"
      system "bundle exec rake test"
    end
  end

  desc "Testing using all gemfiles"
  task :all => gemfile_tasks
end

task :default => 'test:all'

