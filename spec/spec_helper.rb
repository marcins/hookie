require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'rspec'
require 'hookie'

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter     = 'documentation'
end