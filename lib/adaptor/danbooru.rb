class Adaptor::DanbooruAdaptor < Adaptor::BaseAdaptor
  def post(resp, url = nil)
    body = resp
    if Faraday::Response === resp
      body = resp.body
      url = resp.env.url
    end

    if Array === body
      raise "more than one result" if body.size > 1
      body = body.first
    end

    url = url.clone
    url.path = "/post/show/#{body['id']}"

    tags = body["tags"].split(" ")
    tags << "imported"
    tags << "imported:danbooru1"

    Post.new(url: url,
	     id: body["id"],
	     source: body["source"],
	     image_url: body["file_url"],
	     tags: tags,
	     rating: body["rating"].to_sym)
  end

  def wiki_page(resp)
    body = resp.body
    if Array === body
      body = body.first
    end

    url = resp.env.url.clone
    url.path = "/wiki/show?title=#{body['id']}"

    WikiPage.new(url: resp.env.url.to_s.gsub(/\.json$/, ""),
		 id: body["id"],
		 title: body["title"],
		 body: body["body"],
		 other_names: body["other_names"])
  end

  def rating(rating)
    rating
  end

  def rating_from(rating)
    rating
  end

  def tag_category(category)
    case category
    when 0
      :general
    when 1
      :artist
    when 3
      :copyright
    when 4
      :character
    when 5
      :meta
    else
      :unknown
    end
  end

  def tag(resp)
    result = resp.body
    if Array === result
      result = result.first
    end
    Tag.new(url: resp.env.url.to_s,
	    id: result["id"],
	    name: result["name"],
	    category: tag_category(result["category"]))
  end

  def pool(resp)
    result = resp.body
    if Array === result
      result = result.first
    end
    Pool.new(url: resp.env.url.to_s,
	     id: result["id"],
	     name: result["name"].gsub("_", " "),
	     description: result["description"],
	     category: result["category"],
	     post_ids: result["post_ids"])
  end
end
