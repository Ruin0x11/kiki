class Adaptor::Danbooru2Adaptor < Adaptor::BaseAdaptor
  def post(resp)
    Post.new(url: resp.env.url.to_s,
	     id: resp.body["id"],
	     source: resp.body["source"],
	     image_url: resp.body["large_file_url"],
	     tags: resp.body["tag_string"].split(" "),
	     rating: resp.body["rating"].to_sym)
  end

  def upload(resp)
    Post.new(url: resp.env.url.to_s,
	     id: resp.body["post_id"],
	     source: resp.body["source"],
	     image_url: nil,
	     tags: resp.body["tag_string"].split(" "),
	     rating: resp.body["rating"].to_sym)
  end

  def wiki_page(resp)
    result = resp.body
    if Array === result
      result = result.first
    end
    WikiPage.new(url: resp.env.url.to_s,
		 id: result["id"],
		 title: result["title"],
		 body: result["body"],
		 other_names: result["other_names"])
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
