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
