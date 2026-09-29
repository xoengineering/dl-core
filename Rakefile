require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

Dir.glob('tasks/*.rake').each { |task_file| load task_file }

task default: %i[spec rubocop]
