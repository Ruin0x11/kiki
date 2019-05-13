class Client::Danbooru2Client < Client::BaseClient
  def initialize(domain, username, auth)
    super

    @conn = Faraday.new(url: "https://#{domain}") do |faraday|
      faraday.response :json, content_type: /\bjson$/
      faraday.basic_auth username, auth

      faraday.use Faraday::Request::Retry
      faraday.use Faraday::Response::Logger
      faraday.use Faraday::Adapter::NetHttp
    end
  end

  def parse_uri(uri)
    uri = URI.parse(uri) unless URI === uri
    return {type: nil, id: nil} unless @domain == uri.host

    m = uri.path.match(/posts\/([0-9]+)$/)
    return {type: :post, id: m[1].to_i} if m

    m = uri.path.match(/wiki_pages\/([0-9]+)$/)
    return {type: :wiki_page, id: m[1].to_i} if m

    m = uri.path.match(/pools\/([0-9]+)$/)
    return {type: :post, id: m[1].to_i} if m

    {type: nil, id: nil}
  end

  def get_post(id)
    @conn.get "/posts/#{id}.json"
  end

  def get_wiki_page(id)
    @conn.get "/wiki_pages/#{id}.json"
  end

  def get_pool(id)
    @conn.get "/pools/#{id}.json"
  end
end
