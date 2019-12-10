require "ostruct"

require "lib/shaarli_client"

class Importer
  def initialize(instance)
    @client = ShaarliClient.new(instance)
  end

  def run!(count)
    links = @client.links(tags: ["b"], limit: count).map { |i| OpenStruct.new i }

    user = User.find_by_name("ruin")
    raise "Unable to find user" if user.nil?

    server_to = Server.find_matching("http://bijutsu.nori.daikon")
    raise "Unable to find server" if server_to.nil?

    links.each do |link|
      server_from = Server.find_matching(link.url)
      if server_from.nil?
	puts "No matching server for url #{link.url}"
	next
      end

      order = Order.create(user: user,
			   server_from: server_from,
			   server_to: server_to,
			   url: link.url,
			   status: :created)

      if order.valid?
	puts "imported shaarli link (#{link.id}): #{link.url}"

	tags = link.tags
	tags.delete("b")
	tags << "b_imported"
	@client.update_link(link.id, title: [link.title], description: [link.description], tags: tags, private: link.private, url: link.url)
      else
	raise "could not create import job (#{link.id}): #{link.url} #{order.errors.full_messages}"
      end
    end
  end
end
