class Adaptor::SzurubooruAdaptor < Adaptor::BaseAdaptor
  def post(resp)
    Post.new(url: resp.env.url.to_s,
	     id: resp.body["id"],
	     source: resp.body["source"],
	     image_url: "#{resp.env.url.scheme}://#{resp.env.url.host}/#{resp.body['contentUrl']}",
	     tags: resp.body["tags"].map { |t| t["names"][0] } ,
	     rating: rating(resp.body["safety"].to_sym))
  end

  def upload(resp)
    post(resp)
  end

  def rating(safety)
    case safety
    when :safe
      :s
    when :sketchy
      :q
    when :unsafe
      :e
    end
  end

  def rating_from(safety)
    case safety
    when :s
      :safe
    when :q
      :sketchy
    when :e
      :unsafe
    end
  end

  def tag(resp)
    result = resp.body
    if Array === result
      result = result.first
    end
    Tag.new(url: resp.env.url.to_s,
	    id: result["names"][0],
	    name: result["names"][0],
	    category: result["category"].to_sym)
  end
end
