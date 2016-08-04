$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "dagraph/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dagraph"
  s.version     = Dagraph::VERSION
  s.authors     = ["Nikolay Mikhaylichenko"]
  s.email       = ["nn.mikh@yandex.ru"]
  s.homepage    = "https://github.com/nmix/dagraph"
  s.summary     = "Directed Acyclic Graph"
  s.description = "Directed Acyclic Graph"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2.6"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails" 
  s.add_development_dependency "factory_girl_rails" 
  s.add_development_dependency "faker" 
  s.add_development_dependency "database_cleaner"
end
