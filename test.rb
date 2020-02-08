$LOAD_PATH.unshift File.expand_path("..", __FILE__)

require "faraday"
require "faraday_middleware"
require "lib/client"
require "lib/iqdb_client"

# @db = Client::Danbooru2Client.new("https://danbooru.donmai.us", "necoma", "Owpt0cA9jy7yvzGWHLwt1_TZ1JpkNaEsq_e5YVZHbV0")
# post = @db.get_post(123)
# tag = @db.get_tag(101)

# @client = Client::SzurubooruClient.new("http://bijutsu.nori.daikon", "nonbirithm", "ac05b444-7458-4863-96c5-2ee6487199dd")

# post = @client.search_posts("imported\\:image", limit: 1)[0]
# pp post
# post.tags << "dood"
# pp @client.update_post(post)

# @iqdb = IQDBClient.new("https://www.iqdb.org")
#
# file = "/mnt/hibiki/back/Camera/JapanII/DCIM/Camera/IMG_20191227_103113.jpg"
# pp @iqdb.query(file)
