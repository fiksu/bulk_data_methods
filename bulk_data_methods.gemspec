$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'bulk_data_methods/version'

Gem::Specification.new do |s|
  s.name         = "bulk_data_methods"
  s.version      = BulkDataMethods::VERSION
  s.license      = 'New BSD License'
  s.date         = '2013-10-10'
  s.summary      = 'MixIn used to extend ActiveRecord::Base classes implementing bulk insert and update operations through {#create_many} and {#update_many}.'
  s.description  = 'MixIn used to extend ActiveRecord::Base classes implementing bulk insert and update operations through {#create_many} and {#update_many}.'
  s.authors      = ["Keith Gabryelski"]
  s.email        = 'keith@fiksu.com'
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.homepage     = 'http://github.com/fiksu/bulk_data_methods'
  s.add_dependency "pg"
  s.add_dependency "activerecord", '>= 4.0', '< 5.0'
  s.add_development_dependency "rails", '>= 4.0', '< 5.0'
  s.add_development_dependency "rspec-rails"
end
