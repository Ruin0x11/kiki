$LOAD_PATH.unshift File.expand_path("..", __FILE__)

require "config/environment"
require "models/init"

Importer.new(settings.shaarli_instance).run! settings.import_post_count, ["b_failed"]
