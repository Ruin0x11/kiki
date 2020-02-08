require "ostruct"

require "lib/shaarli_client"

class Importer
  def initialize(instance)
    @client = ShaarliClient.new(instance)
  end

  def run!(count, tags = nil)
    tags ||= ["b"]
    links = @client.links(tags: tags, limit: count).map { |i| OpenStruct.new i }.reverse

    user = User.find_by_name("ruin")
    raise "Unable to find user" if user.nil?

    server_to = Server.find_matching("http://bijutsu.nori.daikon")
    raise "Unable to find server" if server_to.nil?

    links.each do |link|
      url = link.url.gsub(/\/$/, "")
      server_from = Server.find_matching(url)
      if server_from.nil?
	puts "No matching server for url #{url}"
	next
      end

      order = Order.create(user: user,
			   server_from: server_from,
			   server_to: server_to,
			   url: url,
			   status: :created)

      link_tags = link.tags

      tags.each { |t| link_tags.delete(t) }

      if order.valid?
	puts "imported shaarli link (#{link.id}): #{url}"
	link_tags << "b_imported"
	link.description = ""
      else
	puts "could not create import job (#{link.id}): #{url} #{order.errors.full_messages}"
	link_tags << "b_failed"
	link.description = order.errors.full_messages
      end

      @client.update_link(link.id, title: [link.title], description: [link.description], tags: link_tags, private: link.private, url: url)
    end
  end
end
