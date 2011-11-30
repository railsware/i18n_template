# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "i18n_template/version"

Gem::Specification.new do |s|
  s.name        = "i18n_template"
  s.version     = I18nTemplate::VERSION
  s.authors     = ["Nikolai Lugovoi", "Yaroslav Lazor", "Andriy Yanko"]
  s.email       = ["andriy.yanko@gmail.com"]
  s.homepage    = "https://github.com/railsware/i18n_template"
  s.summary     = %q{I18nTemplate is made to extract phrases from html/xhtml/xml documents and translate them on the fly}
  s.description = %q{
I18nTemplate is made to extract phrases and translate templates.
Currently I18nTemplate can work with (x)html documents.
Translation is done by modify the original template (on the fly) to be translated on erb execution time.
}

  s.rubyforge_project = "template_i18n"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "actionpack", ">=2.3.0"
end
