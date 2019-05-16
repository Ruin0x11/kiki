class Adaptor::Danbooru2Adaptor < Adaptor::BaseAdaptor
  def post(resp)
    Post.new(url: resp.env.url.to_s,
	     id: resp.body["id"],
	     source: resp.body["large_file_url"],
	     tags: resp.body["tag_string"].split(" "),
	     rating: resp.body["rating"])
  end

  def wiki_page(resp)
    WikiPage.new(url: resp.env.url.to_s,
		 id: resp.body["id"],
		 title: resp.body["title"],
		 body: resp.body["body"],
		 other_names: resp.body["other_names"])
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
    Tag.new(url: resp.env.url.to_s,
	    id: resp.body["id"],
	    name: resp.body["name"],
	    category: tag_category(resp.body["category"]))
  end

  def pool(resp)
    Pool.new(url: resp.env.url.to_s,
	     id: resp.body["id"],
	     name: resp.body["name"].gsub("_", " "),
	     description: resp.body["description"],
	     category: resp.body["category"],
	     post_ids: resp.body["post_ids"])
  end
end
