require "lib/structs"

module Adaptor
end

class Adaptor::BaseAdaptor
  def post(resp)
  end

  def wiki_page(resp)
  end

  def tag(resp)
  end

  def pool(resp)
  end

  def rating(rating)
  end

  def rating_from(rating)
  end
end

require "lib/adaptor/danbooru"
require "lib/adaptor/danbooru2"
require "lib/adaptor/szurubooru"
