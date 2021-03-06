require "set"
require "lib/adaptor"

class Client::Danbooru2Client < Client::BaseClient
  attr_reader :conn

  def initialize(domain, username, auth)
    super

    @ada = Adaptor::Danbooru2Adaptor.new
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

    pp uri
    m = uri.path.match(/posts\/([0-9]+)/)
    return {type: :post, id: m[1].to_i} if m

    m = uri.path.match(/wiki_pages\/([0-9]+)/)
    return {type: :wiki_page, id: m[1].to_i} if m

    m = uri.path.match(/pools\/([0-9]+)/)
    return {type: :post, id: m[1].to_i} if m

    {type: nil, id: nil}
  end

  def has_wiki_pages?
    true
  end

  def has_pools?
    true
  end

  def get_post(id)
    r = @conn.get "/posts/#{id}.json"
    Result.make(r) { |resp| @ada.post(resp) }
  end

  def upload_post(post)
    params = { "source" => post.source, "tag_string" => post.tags.join(" "), "rating" => post.rating.to_s }
    params["parent_id"] = post.parent_id unless post.parent_id.nil?

    r = @conn.post "/uploads.json", params
    Result.make(r) { |resp| @ada.upload(resp) }
  end

  def get_tag(id)
    r = @conn.get "/tags/#{id}.json"
    return Result.failure(r) if r.body.empty?
    Result.make(r) { |resp| @ada.tag(resp) }
  end

  def find_tag_by_name(name)
    r = @conn.get "/tags.json", { "search" => { "name" => name } }
    return Result.failure(r) if r.body.empty?
    Result.make(r) { |resp| @ada.tag(resp) }
  end

  def create_tag(tag)
    r = @conn.post "/tags.json", { "name" => tag.name, "category" => tag.category }
    Result.make(r) { |resp| @ada.tag(resp) }
  end

  def get_wiki_page(id)
    r = @conn.get "/wiki_pages/#{id}.json"
    Result.make(r) { |resp| @ada.wiki_page(resp) }
  end

  def find_wiki_page_by_name(name)
    r = @conn.get "/wiki_pages.json", { "search" => { "title" => name } }
    return Result.failure(r) if r.body.empty?
    Result.make(r) { |resp| @ada.wiki_page(resp) }
  end

  def create_wiki_page(wiki_page)
    r = @conn.post "/wiki_pages.json", { "title" => wiki_page.title, "body" => "#{wiki_page.body}\n\n#{pool_metadata(wiki_page.url)}", "other_names" => wiki_page.other_names.join(" ") }
    Result.make(r) { |resp| @ada.wiki_page(resp) }
  end

  def get_pool(id)
    r = @conn.get "/pools/#{id}.json"
    Result.make(r) { |resp| @ada.pool(resp) }
  end

  # def find_pool_by_name(name)
  #   r = @conn.get "/pools.json", { "search" => { "name_matches" => name } }
  #   Result.make(r) { |resp| @ada.pool(resp) }
  # end

  def find_pool_by_source(source)
    r = @conn.get "/pools.json", { "search" => { "description_matches" => pool_metadata(source) } }
    Result.make(r) { |resp| @ada.pool(resp) }
  end

  def create_pool(pool)
    r = @conn.post "/pools.json", { "name" => pool.name, "description" => "#{pool.description}\n\n#{pool_metadata(pool.url)}", "category" => pool.category }
    Result.make(r) { |resp| @ada.pool(resp) }
  end

  def add_post_to_pool(id, to_add)
    pool = get_pool id
    return pool.result unless pool.success?

    post_ids = pool
      .post_ids
      .split(" ")
      .map(&:to_i)
      .to_set
      .unshift(id)

    r = @conn.put "/pools/#{id}.json", {"post_ids" => post_ids.to_a.join(" ")}
    Result.make(r) { |resp| @ada.pool(resp) }
  end
end
