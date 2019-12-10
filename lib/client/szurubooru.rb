require "set"
require "lib/adaptor"
require "base64"
require "faraday/param_part"
require "stringio"

class Client::SzurubooruClient < Client::BaseClient
  attr_reader :conn

  def initialize(domain, username, auth)
    super

    @ada = Adaptor::SzurubooruAdaptor.new
    @conn = Faraday.new(url: domain) do |faraday|
      faraday.request :json
      faraday.request :multipart
      faraday.response :json, content_type: "application/json"
      faraday.authorization :Token, Base64.strict_encode64("#{username}:#{auth}")
      faraday.headers["Accept"] = "application/json"

      faraday.use Faraday::Request::Retry
      faraday.use Faraday::Response::Logger
      faraday.adapter Faraday::Adapter::NetHttp
    end
  end

  def parse_uri(uri)
    uri = URI.parse(uri) unless URI === uri
    return {type: nil, id: nil} unless @domain == uri.host

    m = uri.path.match(/post\/([0-9]+)$/)
    return {type: :post, id: m[1].to_i} if m

    {type: nil, id: nil}
  end

  def has_wiki_pages?
    false
  end

  def has_pools?
    false
  end

  def upload_post(post)
    metadata = {
      "source" => post.source,
      "tags" => post.tags,
      "safety" => @ada.rating_from(post.rating),
      "contentUrl" => post.image_url
    }

    image = @conn.get do |req|
      req.url post.image_url
      req.headers["Referrer"] = post.url
    end

    payload = {
      metadata: Faraday::ParamPart.new(metadata.to_json, "application/json"),
      content: Faraday::FilePart.new(StringIO.new(image.body), image.headers["content-type"]),
    }

    r = @conn.post "/api/posts", payload, "Content-Type" => "multipart/form-data"
    return Result.failure(r) if r.body["name"]
    Result.make(r) { |resp| @ada.upload(resp) }
  end

  def get_post(id)
    r = @conn.get "/api/post/#{id}"
    Result.make(r) { |resp| @ada.post(resp) }
  end

  def find_tag_by_name(name)
    r = @conn.get "/api/tag/#{name}"
    return Result.failure(r) if r.body["name"]
    Result.make(r) { |resp| @ada.tag(resp) }
  end

  def create_tag(tag)
    r = @conn.post "/api/tags", { "names" => [tag.name], "category" => tag.category }
    Result.make(r) { |resp| @ada.tag(resp) }
  end
end
