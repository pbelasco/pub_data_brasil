# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'json'

Rails::Initializer.run do |config|  
  

  config.gem "hpricot", :version => '0.8.1'
  config.gem "curb", :version => '0.5.4.0'
  # config.gem "capistrano", :version => '2.5.8'Proposicao
  config.gem "capistrano-ext",  :version => '1.2.1' , :lib => "capistrano"
  config.gem "mysql"
  config.gem 'RedCloth', :version => '4.2.2'
  config.gem 'authlogic', :version => "2.1.2"
  config.gem 'collectiveidea-delayed_job', :lib => 'delayed_job', :source => 'http://gems.github.com'
  config.time_zone = 'Brasilia'
  config.gem 'thinking-sphinx', :lib => 'thinking_sphinx', :version => '1.3.18'
  

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  config.i18n.default_locale = :ptbr
end

