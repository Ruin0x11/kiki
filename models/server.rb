require "uri"
require "lib/client"

class Server < ActiveRecord::Base
  enum api_type: [:danbooru, :danbooru2, :gelbooru, :szurubooru]

  has_many :orders

  def self.find_matching(url)
    uri = URI.parse(url)
    Server.find_by_domain(uri.scheme + "://" + uri.host)
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
		 end
  end
end
