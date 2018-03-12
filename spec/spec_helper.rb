require 'rspec/its'
require 'rspec/given'
require 'pry'

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

require 'stepladder'

RSpec.configure do |cfg|
  cfg.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  cfg.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end
