require "lib/client/danbooru2"

class Client::DanbooruClient < Client::BaseClient
  attr_reader :conn

  def initialize(domain, username, auth)
    super

    @ada = Adaptor::DanbooruAdaptor.new
    @conn = Faraday.new(url: domain) do |faraday|
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
      faraday.basic_auth username, auth

      faraday.use Faraday::Request::Retry
      faraday.use Faraday::Response::Logger
      faraday.adapter Faraday::Adapter::NetHttp
    end
  end

  def parse_uri(uri)
    uri = URI.parse(uri) unless URI === uri
    return {type: nil, id: nil} unless @domain.host == uri.host

    m = uri.path.match(/post\/show\/([0-9]+)/)
    return {type: :post, id: m[1].to_i} if m

    # m = uri.path.match(/wiki_pages\/([0-9]+)/)
    # return {type: :wiki_page, id: m[1].to_i} if m

    # m = uri.path.match(/pools\/([0-9]+)/)
    # return {type: :post, id: m[1].to_i} if m

    {type: nil, id: nil}
  end

  def has_wiki_pages?
    true
  end

  def has_pools?
    true
  end

  def get_post(id)
    r = @conn.get "/post.json", { "tags" => "id:#{id}" }
    Result.make(r) { |resp| @ada.post(resp) }
  end

  def get_tag(id)
    r = @conn.get "/tag.json", { "id" => id }
    return Result.failure(r) if r.body.empty?
    Result.make(r) { |resp| @ada.tag(resp) }
  end

  def find_tag_by_name(name)
    r = @conn.get "/tag.json", { "name" => name }
    return Result.failure(r) if r.body.empty?
    Result.make(r) { |resp| @ada.tag(resp) }
  end

  def get_wiki_page(id)
    r = @conn.get "/wiki.json", { "id" => id }
    Result.make(r) { |resp| @ada.wiki_page(resp) }
  end

  def find_wiki_page_by_name(name)
    r = @conn.get "/wiki.json", { "query" => name }
    return Result.failure(r) if r.body.empty?
    Result.make(r) { |resp| @ada.wiki_page(resp) }
  end

  def get_pool(id)
    r = @conn.get "/pool.json", { "id" => id }
    Result.make(r) { |resp| @ada.pool(resp) }
  end

  # def find_pool_by_name(name)
  #   r = @conn.get "/pools.json", { "search" => { "name_matches" => name } }
  #   Result.make(r) { |resp| @ada.pool(resp) }
  # end
end
