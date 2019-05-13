class Processor
  def initialize(order)
    @order = order
    @client_from = order.server_from.client
    @client_to = order.server_to.client
  end

  def process!
    begin
      case @client_from.url_type(@order.url)
      when :post
	move_post(@order.url)
      when :wiki_page
	move_wiki_page(@order.url)
      when :pool
	move_pool(@order.url)
      else
	[:failure, "unknown url type"]
      end
    rescue Exception => e
      [:failure, e.to_s]
    end
  end

  def move_post(uri)
    post = @client_from.get_post(@order.item_id)
    @client_to.upload_post(post)

    [:success, nil]
  end

  def move_wiki_page(uri)
    [:failure, nil]
  end

  def move_pool(uri)
    [:failure, nil]
  end
end
