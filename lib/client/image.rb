require "set"
require "lib/adaptor"
require "base64"
require "faraday/param_part"
require "stringio"

class Client::ImageClient < Client::BaseClient
  attr_reader :conn

  def initialize(domain, username, auth)
    super

    @conn = Faraday.new(url: URI.parse(domain).host) do |faraday|
      faraday.use Faraday::Request::Retry
      faraday.use Faraday::Response::Logger
      faraday.adapter Faraday::Adapter::NetHttp
    end
  end

  def parse_uri(uri)
    return {type: :post, id: nil}
  end

  def has_wiki_pages?
    false
  end

  def has_pools?
    false
  end

  def get_post(id)
    r = @conn.get id

    url = (@conn.url_prefix + id).to_s

    Result.make(r) { |resp| Post.new(url: url,
				     id: 0,
				     source: url,
				     image_url: url,
				     tags: ["imported", "imported:image"],
				     rating: :s
				    ) }
  end

  def find_tag_by_name(name)
    Result.success(Tag.new(url: "", id: 0, name: name, category: "general"))
  end
end
