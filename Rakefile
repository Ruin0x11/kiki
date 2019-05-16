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

task default: [:test]
