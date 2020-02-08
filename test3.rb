$LOAD_PATH.unshift File.expand_path("..", __FILE__)

require "faraday"
require "faraday_middleware"
require "lib/client"
require "lib/iqdb_client"

require "config/environment"
require "models/server"

def add_missing_tags(client_from, client_to, post)
  post.tags.each do |tag|
    # tag
    unless client_to.find_tag_by_name(tag).success?
      new_tag = client_from.find_tag_by_name(tag)
      if !new_tag.success?
	new_tag = Result.success(Tag.new(id: 0, name: tag, url: "", category: :general))
      end

      puts "make tag #{new_tag.inspect}"
      resp = client_to.create_tag(new_tag)
      raise "could not create tag '#{tag}' in sink" unless resp.success?
    end

    # wiki page
    if client_to.has_wiki_pages?
      unless client_to.find_wiki_page_by_name(tag).success?
	resp = client_from.find_wiki_page_by_name(tag)
	if resp.success?
	  resp = client_to.create_wiki_page(resp.result)
	  raise "could not create wiki page '#{tag}' in sink" unless resp.success?
	end
      end
    end
  end
end

def work
  client_to = Client::SzurubooruClient.new("http://bijutsu.nori.daikon",
					   "nonbirithm",
					   "ac05b444-7458-4863-96c5-2ee6487199dd")
  iqdb = IQDBClient.new("https://www.iqdb.org")

  posts = client_to.search_posts("tag-count:0..0 -ran_iqdb\\:#{settings.iqdb_similarity_threshold}")

  faraday = Faraday.new

  posts.each do |post|
    # sleep settings.iqdb_delay_secs

    post.tags << "ran_iqdb:#{settings.iqdb_similarity_threshold}"

    resp = faraday.get(post.image_url)
    raise "could not download" unless resp.status == 200

    if resp.body.size > 1 * 1024 * 1024 # 8 * 1024 * 1024
      puts "Image is too large: #{resp.body.size}"
      next
    end

    candidates = iqdb.query(StringIO.new resp.body)
    best = nil
    server_from = nil

    candidates.each do |cand|
      pp cand
      next unless cand.similarity >= settings.iqdb_similarity_threshold
      server_from = Server.find_matching(cand.source)
      if server_from != nil
	best = cand
	break
      end
    end

    if best.nil?
      puts "Could not find similar image (post #{post.id}): #{best}"
      client_to.update_post(post)
      next
    end

    if server_from.nil?
      puts "Unable to find server for URL #{url}"
      client_to.update_post(post)
      next
    end

    client_from = server_from.client
    parsed = client_from.parse_uri(best.source)

    raise "invalid" unless parsed[:type] == :post
    post_from = client_from.get_post(parsed[:id])

    add_missing_tags client_from, client_to, post

    pp post_from
    post.tags.concat(post_from.tags)
    post.tags << "imported:iqdb"

    upd = client_to.update_post(post)

    puts "Added tags: #{upd.tags.inspect}"
  end
end

work
