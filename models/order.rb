class Order < ActiveRecord::Base
  enum url_type: [:post, :wiki_page, :pool]

  has_many :receipts

  belongs_to :user
  belongs_to :server_from, class_name: "Server"
  belongs_to :server_to, class_name: "Server"

  before_validation :parse_url

  validate :servers_are_different
  validates_presence_of :url_type, :url_id

  private

  def servers_are_different
    errors.add :server, message: "Servers must be different" if server_from == server_to
  end

  def parse_url
    data = server_from.client.parse_uri(url)
    pp data
    self.url_type = data[:type]
    self.url_id = data[:id]
  end
end
