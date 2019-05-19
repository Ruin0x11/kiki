class Order < ActiveRecord::Base
  enum url_type: [:post, :wiki_page, :pool]

  has_many :receipts

  belongs_to :user
  belongs_to :server_from, class_name: "Server"
  belongs_to :server_to, class_name: "Server"

  before_validation :parse_url
  after_create :queue

  validates_presence_of :server_from, :server_to
  validate :servers_are_different
  validates_presence_of :url_type, :url_id

  def queue
    Delayed::Job.enqueue self
  end

  def perform
    result, message = Processor.new(self).process!
    self.finished = result == :success

    Receipt.create!(order: self, result: result, message: message)
    save!
  end

  def latest_receipt
    Receipt.where(order: self).order_by(created_at: :desc).first
  end

  private

  def servers_are_different
    errors.add :server, message: "Servers must be different" if server_from == server_to
  end

  def parse_url
    return if self.url_type and self.url_id

    data = server_from.client.parse_uri(url)
    self.url_type = data[:type]
    self.url_id = data[:id]
  end
end
