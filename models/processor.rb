class Processor
  def initialize(order, client_from = nil, client_to = nil)
    @order = order
    @client_from = client_from || order.server_from.client
    @client_to = client_to || order.server_to.client
  end

  def process!
    begin
      case @order.url_type
      when :post
	copy_post(@order.url_id)
      when :wiki_page
	copy_wiki_page(@order.url_id)
      when :pool
	copy_pool(@order.url_id)
      else
	[:failure, "unknown url type", nil]
      end
    rescue Faraday::TimeoutError => e
      [:timeout, e.to_s, nil]
    rescue Exception => e
      [:failure, e.to_s, nil]
    end
  end

  def copy_post(id)
    resp = @client_from.get_post(id)
    return failure "could not find post '#{id}' in source", resp unless resp.success?

    source = resp.source
    tags = resp.tags
    rating = resp.rating

    tags.each do |tag|
      tag_resp = @client_to.find_wiki_page_by_name(tag)
      unless tag_resp.success?
	# tag
	resp = @client_from.find_tag_by_name(tag)
	return failure "could not find tag '#{tag}' in source", resp unless resp.success?

	category = resp.body["category"]
	resp = @client_to.create_tag(tag, category)
	return failure "could not create tag '#{tag}' in sink", resp unless resp.success?

	# wiki page
	resp = @client_from.find_wiki_page_by_name(tag)
	return failure "could not find wiki page '#{tag}' in source", resp unless resp.success?

	source = resp.source
	title = resp.title
	body = resp.body
	other_names = resp.other_names
	resp = @client_to.create_wiki_page(source, title, body, other_names)
	return failure "could not create wiki page '#{tag}' in sink", resp unless resp.success?
      end
    end

    resp = @client_to.upload_post(source, tags, rating)
    return failure "could not upload post '#{source}' to sink", resp unless resp.success?

    [:success, nil, resp]
  end

  def copy_wiki_page(id)
    resp = @client_from.get_wiki_page(id)
    return failure "could not find wiki page '#{id}' in source", resp unless resp.success?

    resp = @client_to.create_wiki_page(post.body)
    return failure "could not create wiki page in sink", resp unless resp.success?

    [:success, nil, resp]
  end

  def copy_pool(id)
    resp = @client_from.get_pool(id)
    return failure "could not find pool '#{id}' in source", resp unless resp.success?

    [:failure, nil, nil]
  end

  private

  def failure(message, resp)
    [:failure, message, resp]
  end
end
