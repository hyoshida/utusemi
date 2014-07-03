$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "utusemi/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "utusemi"
  s.version     = Utusemi::VERSION
  s.authors     = ['YOSHIDA Hiroki']
  s.email       = ['hyoshida@appirits.com']
  s.homepage    = 'https://github.com/hyoshida/utusemi#utusemi'
  s.summary     = "TODO: Summary of Utusemi."
  s.description = "TODO: Description of Utusemi."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 4.1.2"
end
