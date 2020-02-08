require "set"
require "lib/adaptor"
require "base64"
require "faraday/param_part"
require "stringio"

require "lib/client/szurubooru/connection"

class Client::SzurubooruClient < Client::BaseClient
  attr_reader :conn

  def initialize(domain, username, auth)
    super

    @ada = Adaptor::SzurubooruAdaptor.new
    @conn = Connection.new(domain, username, auth)
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

  # Search posts
  #
  # @param query [String] Search term and qualifiers
  # @param options [Hash] Sort and pagination options
  # @option options [Integer] :offset Post offset for pagination.
  # @option options [Integer] :limit Number of items per page
  # @return [Faraday::Response] Search results object
  def search_posts(query, options = {})
    r = search "/api/posts", query, options
    Result.make(r) do |resp|
      resp.body["results"].map do |post|
	@ada.post(post, URI.parse("#{@domain}/post/#{post['id']}"))
      end
    end
  end

  def upload_post(post)
    metadata = {
      "source" => post.url, # post.source,
      "tags" => post.tags,
      "safety" => @ada.rating_from(post.rating),
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

  def update_post(post)
    r = @conn.put "/api/post/#{post.id}", {
      "version" => post.version,
      "source" => post.url, # post.source,
      "tags" => post.tags,
      "safety" => @ada.rating_from(post.rating),
    }
    Result.make(r) { |resp| @ada.post(resp) }
  end

  private

  def search(path, query, options = {})
    opts = options.merge("query" => query)
    @conn.paginate(path, opts) do |data, last_response|
      data.items.concat last_response.data.items
    end
  end
end
