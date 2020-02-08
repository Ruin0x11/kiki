$LOAD_PATH << File.dirname(File.expand_path(__FILE__)) + "/.."
ENV["RACK_ENV"] ||= "development"

require "rubygems"
require "bundler"
Bundler.require(:default, ENV["RACK_ENV"])

Delayed::Worker.backend = :active_record
Delayed::Worker.destroy_failed_jobs = true
Delayed::Worker.sleep_delay = 5
Delayed::Worker.max_attempts = 5
Delayed::Worker.max_run_time = 5.minutes

set :logger, Logger.new(STDERR)
set :import_post_count, 50000
set :shaarli_instance, "nori"
set :iqdb_delay_secs, 60 * 10
set :iqdb_similarity_threshold, 90
