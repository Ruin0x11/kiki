require_relative "../config/environment"
require "minitest/autorun"
require "mocha/minitest"
require "shoulda"

class BaseTest < ActiveSupport::TestCase
  def initialize(it)
    super

    @testdir = File.dirname(__FILE__)
  end

  def read_fixture(path)
    path = File.join(@testdir, "fixtures", path)
    JSON.parse(File.read(path))
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    # with.library :rails
  end
end
