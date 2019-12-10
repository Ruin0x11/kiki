$LOAD_PATH << File.dirname(File.expand_path(__FILE__))
require "./config/environment"
require './kiki'
require 'sinatra/activerecord/rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
  t.libs << "."
  t.libs << "lib"
  t.libs << "kiki"
  t.libs << "test"
end

namespace :db do
  desc 'Drop, create, migrate then seed the development database'
  task reseed: [ 'db:drop', 'db:create', 'db:migrate', 'db:seed' ] do
    puts 'Reseeding completed.'
  end
end

namespace :jobs do
  desc "Clear the delayed_job queue."
  task :clear do
    Delayed::Job.delete_all
  end

  desc "Start a delayed_job worker."
  task :work do
    Delayed::Worker.new(:min_priority => ENV['MIN_PRIORITY'], :max_priority => ENV['MAX_PRIORITY']).start
  end
end

namespace :import do
  desc "Import from shaarli."
  task :execute do
    Importer.run! settings.import_post_count
  end
end

task default: [:test]
