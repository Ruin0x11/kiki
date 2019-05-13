module Client
end

class Client::BaseClient
  def initialize(domain, username, auth)
    @domain = domain
    @username = username
    @auth = auth
  end

  def parse_uri(uri)
    {type: nil, id: nil}
  end

  def get_post(id)
  end

  def get_wiki_page(id)
  end

  def get_pool(id)
  end
end

require "lib/client/danbooru"
require "lib/client/danbooru2"
require "lib/client/gelbooru"
