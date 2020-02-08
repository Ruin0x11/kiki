$LOAD_PATH << File.dirname(File.expand_path(__FILE__))
require "./config/environment"
require "./kiki"
require "sinatra/activerecord/rake"
require "rake/testtask"

require "racksh/irb"

# $rack.post "/order", { "url" => "https://danbooru.donmai.us/posts/2234129" }

Importer.new(settings.shaarli_instance).run! 1
