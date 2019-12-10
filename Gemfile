source "https://rubygems.org"

gem "bcrypt", "~> 3.1"
gem "delayed_job_active_record", "~> 4.1"
gem "faraday", :github => "lostisland/faraday", :branch => "master"
gem "faraday_middleware", "~> 0.13.1"
gem "pg", "~> 1.1"
gem "rake", "~> 12.3"
gem "sinatra", "~> 2.0"
gem "sinatra-activerecord", "~> 2.0"
gem "whenever", require: false

group :test do
  gem "minitest", "~> 5.11"
  gem "mocha", "~> 1.8", require: false
  gem "shoulda", "~> 3.6"
end

group :development do
  gem "sinatra-reloader", "~> 1.0"
  gem "racksh", "~> 1.0"
end

group :development, :test do
  gem "byebug", "~> 11.0"
  gem "irb", "~> 1.0"
  gem "factory_bot", "~> 5.0"
end
