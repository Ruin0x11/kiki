require "uri"
require "net/http"
require "lib/client"

class Server < ActiveRecord::Base
  enum api_type: [:danbooru, :danbooru2, :gelbooru, :szurubooru, :image]

  has_many :orders

  def self.find_matching(url)
    uri = URI.parse(url)
    server = Server.find_by_domain(uri.scheme + "://" + uri.host)
    return server unless server.nil?

    if Server.url_is_image? url
      return Server.find_by_api_type("image")
    end

    nil
  end

  def client
    @client ||= case self.api_type.to_sym
		when :danbooru
    Client::DanbooruClient.new(domain, username, auth)
		when :danbooru2
    Client::Danbooru2Client.new(domain, username, auth)
		when :gelbooru
    Client::GelbooruClient.new(domain, username, auth)
		when :szurubooru
    Client::SzurubooruClient.new(domain, username, auth)
		when :image
    Client::ImageClient.new(domain, username, auth)
		end
  end

  private

  def self.url_is_image?(url)
    resp = Faraday.get(url)
    if resp.success?
      pp resp.headers["Content-Type"]
      return resp.headers["Content-Type"].start_with? "image"
    end
  end
end
