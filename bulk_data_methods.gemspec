$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'bulk_data_methods/version'

Gem::Specification.new do |s|
  s.name         = "bulk_data_methods"
  s.version      = BulkDataMethods::VERSION
  s.license      = 'New BSD License'
  s.date         = '2013-05-30'
  s.summary      = 'MixIn used to extend ActiveRecord::Base classes implementing bulk insert and update operations through {#create_many} and {#update_many}.'
  s.description  = 'MixIn used to extend ActiveRecord::Base classes implementing bulk insert and update operations through {#create_many} and {#update_many}.'
  s.authors      = ["Keith Gabryelski"]
  s.email        = 'keith@fiksu.com'
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.homepage     = 'http://github.com/fiksu/bulk_data_methods'
  s.add_dependency "pg"
  s.add_dependency "activerecord", '>= 3.0.0'
  s.add_development_dependency "rails", '>= 3.0.0'
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "activeresource", '>= 3.0.0'
end
