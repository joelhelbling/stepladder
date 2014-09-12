require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
  t.pattern = 'spec/lib/**/*_spec.rb'
  t.rspec_opts = " --format doc"
end

task default: :spec
