require "models/init"
require "routes/init"

class Kiki < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  enable :raise_errors, :logging
  disable :show_exceptions

  configure :development do
    require "sinatra/reloader"
    register Sinatra::Reloader
    enable :dump_errors
  end

  error Sinatra::NotFound do
    "Not found"
  end

  error do
    env["sinatra.error"].errors
  end
end
