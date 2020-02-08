class Adaptor::SzurubooruAdaptor < Adaptor::BaseAdaptor
  def post(resp, url = nil)
    body = resp
    if Faraday::Response === resp
      body = resp.body
      url = resp.env.url
    end
    Post.new(url: url.to_s,
	     id: body["id"],
	     source: body["source"],
	     image_url: "#{url.scheme}://#{url.host}/#{body["contentUrl"]}",
	     tags: body["tags"].map { |t| t["names"][0] } ,
	     rating: rating(body["safety"].to_sym),
	     version: body["version"])
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
