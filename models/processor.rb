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
	copy_post(@order.url_id, @order.pool_id)
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
      [:failure, "#{e.message}\n#{e.backtrace.join('\n')}", nil]
    end
  end

  def copy_post(id, pool_id = nil)
    if pool_id != nil
      resp = @client_to.get_pool(id)
      return failure "could not find pool '#{pool_id}' in sink", resp unless resp.success?
    end

    resp = @client_from.get_post(id)
    return failure "could not find post '#{id}' in source", resp unless resp.success?
    post = resp.result

    post.tags.each do |tag|
      # tag
      unless @client_to.find_tag_by_name(tag).success?
	resp = @client_from.find_tag_by_name(tag)
	return failure "could not find tag '#{tag}' in source", resp unless resp.success?

	resp = @client_to.create_tag(tag)
	return failure "could not create tag '#{tag}' in sink", resp unless resp.success?
      end

      # wiki page
      unless @client_to.find_wiki_page_by_name(tag).success?
	resp = @client_from.find_wiki_page_by_name(tag)
	if resp.success?
	  resp = @client_to.create_wiki_page(resp.result)
	  return failure "could not create wiki page '#{tag}' in sink", resp unless resp.success?
	end
      end
    end

    resp = @client_to.upload_post(post)
    return failure "could not upload post '#{post.source}' to sink", resp unless resp.success?
    upload = resp.result

    if pool_id != nil
      resp = @client_to.add_post_to_pool(pool_id, upload)
      return failure "could not add post '#{post.source}' to pool '#{pool_id}' in sink", resp unless resp.success?
    end

    [:success, nil, resp]
  end

  def copy_wiki_page(id)
    resp = @client_from.get_wiki_page(id)
    return failure "could not find wiki page '#{id}' in source", resp unless resp.success?

    wiki_page = resp
    resp = @client_to.create_wiki_page(wiki_page)
    return failure "could not create wiki page '#{wiki_page.title}' in sink", resp unless resp.success?

    [:success, nil, resp]
  end

  def copy_pool(id)
    resp = @client_from.get_pool(id)
    return failure "could not find pool '#{id}' in source", resp unless resp.success?

    pool = resp
    resp = @client_to.create_pool(pool)
    return failure "could not create pool '#{pool.title}' in sink", resp unless resp.success?

    pool.post_ids.each do |post_id|
      Order.create!(server_from: @order.server_from,
		    server_to: @order.server_to,
		    uri_type: :post,
		    uri_id: post_id,
		    pool_id: pool.id)
    end

    [:success, nil, resp]
  end

  private

  def failure(message, resp)
    [:failure, message, resp]
  end
end
