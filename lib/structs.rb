Post = Struct.new :id, :url, :source, :tags, :rating, :parent_id, keyword_init: true

WikiPage = Struct.new :id, :url, :title, :body, :other_names, keyword_init: true

Tag = Struct.new :id, :url, :name, :category, keyword_init: true

Pool = Struct.new :id, :url, :name, :description, :category, :post_ids, keyword_init: true

class Result
  attr_reader :result

  def initialize(status, result = nil)
    @status = status
    @result = result
  end

  def self.failure(resp)
    Result.new(:failure, resp)
  end

  def self.success(resp)
    Result.new(:success, resp)
  end

  def self.make(resp)
    return Result.failure(resp) unless resp.success?
    it = yield resp
    Result.success(it)
  end

  def failure?
    @status == :failure
  end

  def success?
    @status == :success
  end

  def method_missing(m, *args, &block)
    @result.send(m, *args, &block)
  end
end
