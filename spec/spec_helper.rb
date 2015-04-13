# spec/awesome_gem/awesome.rb
APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
$: << File.join(APP_ROOT, 'lib') # so rspec knows where your file could be
require 'avatax_taxservice.rb' # this loads the class you want to test
require 'yaml'

RSpec.configure do |config|
  # Use color in STDOUT
  config.color_enabled = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end