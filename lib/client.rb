require "ostruct"
require "lib/structs"

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

  def has_wiki_pages?
    not_implemented
  end

  def has_pools?
    not_implemented
  end

  def get_post(id)
    not_implemented
  end

  def upload_post(post)
    not_implemented
  end

  def update_post(post)
    not_implemented
  end

  def get_tag(id)
    not_implemented
  end

  def find_tag_by_name(name)
    not_implemented
  end

  def create_tag(tag)
    not_implemented
  end

  def get_wiki_page(id)
    not_implemented
  end

  def find_wiki_page_by_name(name)
    not_implemented
  end

  def create_wiki_page(wiki_page)
    not_implemented
  end

  def get_pool(id)
    not_implemented
  end

  def find_pool_by_name(id)
    not_implemented
  end

  def find_pool_by_source(source)
    not_implemented
  end

  def create_pool(pool)
    not_implemented
  end

  def add_post_to_pool(id, post_id)
    not_implemented
  end

  protected

  def pool_metadata(source)
    "(Kiki metadata - Source|#{source})"
  end

  def not_implemented
    Result.failure(OpenStruct.new(status: 0, env: OpenStruct.new(url: "")))
  end
end

require "lib/client/danbooru"
require "lib/client/danbooru2"
require "lib/client/gelbooru"
require "lib/client/szurubooru"
require "lib/client/image"
