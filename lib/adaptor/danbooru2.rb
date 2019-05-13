class Adaptor::Danbooru2Adaptor < Adaptor::BaseAdaptor
  def post(resp)
    Post.new(url: resp.env.url.to_s,
	     id: resp.body["id"],
	     source: resp.body["large_file_url"],
	     tags: resp.body["tags"],
	     rating: resp.body["rating"])
  end

  def wiki_page(resp)
    WikiPage.new(url: resp.env.url.to_s,
		 id: resp.body["id"],
		 title: resp.body["title"],
		 body: resp.body["body"],
		 other_names: resp.body["other_names"])
  end

  def tag(resp)
    Tag.new(url: resp.env.url.to_s,
	    id: resp.body["id"],
	    name: resp.body["name"],
	    category: resp.body["category"])
  end

  def pool(resp)
    Pool.new(url: resp.env.url.to_s,
	     id: resp.body["id"],
	     name: resp.body["name"],
	     description: resp.body["description"],
	     category: resp.body["category"],
	     post_ids: resp.body["post_ids"])
  end
end
