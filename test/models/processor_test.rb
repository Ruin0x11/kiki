# -*- coding: utf-8 -*-
require "test_helper"
require "models/processor"
require "structs"

class ProcessorTest < BaseTest
  setup do
    @order = stub
    @client_from = stub
    @client_to = stub

    @p = Processor.new @order, @client_from, @client_to
  end

  def order_for(type, id)
    @order.expects(:url_type).returns(type)
    @order.expects(:url_id).returns(id)
  end

  def from_has_post
  end

  def from_has_tag
  end

  def from_has_wiki_page
  end

  def from_has_pool
  end

  def to_has_pool
  end

  def failure
    env = stub
    env.expects(:url).returns("https://source")

    resp = stub
    resp.expects(:env).returns(env)
    resp.expects(:status).returns(400)

    Result.failure(resp)
  end

  context "with bad url" do
    should "fail processing" do
      order_for :tag, 1

      status, mes, resp = @p.process!

      assert_equal :failure, status
      assert_equal "unknown url type", mes
      assert_nil resp
    end
  end

  context "with connection timeout" do
    should "timeout processing" do
      order_for :post, 1

      @client_from.expects(:get_post).raises(Faraday::TimeoutError)

      status, mes, resp = @p.process!

      assert_equal :timeout, status
      assert_equal "timeout", mes
      assert_nil resp
    end
  end

  context "with missing data" do
    should "fail getting post" do
      order_for :post, 1

      @client_from.expects(:get_post).returns(failure)

      status, mes, resp = @p.process!

      assert_equal :failure, status
      assert_equal "could not find post '1' in source", mes
      refute_nil resp
    end

    should "fail getting wiki_page" do
      order_for :wiki_page, 1

      @client_from.expects(:get_wiki_page).returns(failure)

      status, mes, resp = @p.process!

      assert_equal :failure, status
      assert_equal "could not find wiki page '1' in source", mes
      refute_nil resp
    end

    should "fail getting pool" do
      order_for :pool, 1

      @client_from.expects(:get_pool).returns(failure)

      status, mes, resp = @p.process!

      assert_equal :failure, status
      assert_equal "could not find pool '1' in source", mes
      refute_nil resp
    end
  end

  context "copy_post" do
    setup do
      order_for :post, 1
      post = Post.new(url: "https://source/posts/1.json",
		      id: 1,
		      source: "https://source/file.png",
		      tags: ["tag1", "tag2"],
		      rating: "s")

      @client_from.expects(:get_post).returns(Result.success(post))
    end

    context "when wiki page exists in sink" do
      setup do
	wiki_page = WikiPage.new(url: "https://source/wiki_pages/1.json",
	      id: 1,
	      title: "Page",
	      body: "body",
	      other_names: ["name"])

	@client_to.expects(:find_wiki_page_by_name).twice.returns(Result.success(wiki_page))
      end

      should "fail if upload fails" do
	@client_to.expects(:upload_post).returns(failure)

	status, mes, resp = @p.process!

	assert_equal :failure, status
	assert_equal "could not upload post 'https://source/file.png' to sink", mes
	refute_nil resp
      end

      should "succeed if upload succeeds" do
	@client_to.expects(:upload_post).returns(Result.success(Post.new))

	status, mes, resp = @p.process!

	assert_equal :success, status
	assert_nil mes
	refute_nil resp
      end
    end

    context "when wiki page does not exist in sink" do
    end
  end
end
