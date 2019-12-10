class Order < ActiveRecord::Base
  enum url_type: [:post, :wiki_page, :pool]
  enum status: [:success, :timeout, :failure, :queued, :pending, :created]

  belongs_to :user
  belongs_to :server_from, class_name: "Server"
  belongs_to :server_to, class_name: "Server"

  before_validation :parse_url
  after_create :queue

  validates_presence_of :server_from, :server_to
  validate :servers_are_different
  validates_presence_of :url_type, :url_id

  def queue
    puts "queuing job #{self.id}: #{self.url}"

    Delayed::Job.enqueue self

    self.status = :queued
    save!
  end

  def perform
    puts "running job #{self.id}: #{self.url}"

    self.status = :pending
    save!

    result, message = Processor.new(self).process!

    self.status = result
    self.message = message
    save!

    puts "job result #{self.id}: #{self.status} #{self.message}"
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
