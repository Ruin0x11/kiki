require "bcrypt"

class User < ActiveRecord::Base
  include BCrypt

  has_many :orders
  has_many :receipts, through: :orders

  def password
    @password ||= Password.new(encrypted_password)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.encrypted_password = @password
  end
end
