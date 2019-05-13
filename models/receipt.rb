class Receipt < ActiveRecord::Base
  enum result: [:failure, :timeout, :success]

  belongs_to :order
end
