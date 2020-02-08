require "uri"
require "net/http"
require "lib/client"

class Server < ActiveRecord::Base
  enum api_type: [:danbooru, :danbooru2, :gelbooru, :szurubooru, :image]

  has_many :orders

  def self.find_matching(uri)
    uri = URI.parse(uri) unless URI === uri
    server = Server.find_by_domain(uri.host)
    return server unless server.nil?

    if Server.url_is_image? uri
      return Server.find_by_api_type("image")
    end

    nil
  end

  def client
    domain_ = URI.parse(scheme + "://" + domain)

    @client ||= case self.api_type.to_sym
		when :danbooru
    Client::DanbooruClient.new(domain_, username, auth)
		when :danbooru2
    Client::Danbooru2Client.new(domain_, username, auth)
		when :gelbooru
    Client::GelbooruClient.new(domain_, username, auth)
		when :szurubooru
    Client::SzurubooruClient.new(domain_, username, auth)
		when :image
    Client::ImageClient.new(domain_, username, auth)
		end
  end

  private

  def self.url_is_image?(url)
    begin
      resp = Faraday.get(url)
      if resp.success?
        pp resp.headers["Content-Type"]
        return resp.headers["Content-Type"].start_with? "image"
      end
    rescue
      return false
    end
  end
end
