# -*- coding: utf-8 -*-
require "test_helper"
require "models/processor"
require "structs"

class ProcessorTest < BaseTest
  setup do
    @order = stub
    @client_from = stub
    @client_to = stub

    @client_from.stubs(:has_wiki_pages?).returns(true)
    @client_from.stubs(:has_pools?).returns(true)
    @client_to.stubs(:has_wiki_pages?).returns(true)
    @client_to.stubs(:has_pools?).returns(true)

    @p = Processor.new @order, @client_from, @client_to
  end

  def order_for(type, id)
    @order.expects(:url_type).returns(type)
    @order.expects(:url_id).returns(id)
    @order.expects(:pool_id).returns(nil)
  end

  def success(it)
    Result.success it
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

    should "fail getting wiki page" do
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
		      tags: ["tag1"],
		      rating: :s)
      @client_from.expects(:get_post).returns(success(post))
    end

    context "when wiki page and tags exist in sink" do
      setup do
	@client_to.expects(:find_wiki_page_by_name)
	  .returns(success(WikiPage.new))
	@client_to.expects(:find_tag_by_name)
	  .returns(success(Tag.new))
      end

      should "fail if upload fails" do
	@client_to.expects(:upload_post).returns(failure)

	status, mes, resp = @p.process!

	assert_equal :failure, status
	assert_equal "could not upload post 'https://source/file.png' to sink", mes
	refute_nil resp
      end

      should "succeed if upload succeeds" do
	@client_to.expects(:upload_post)
	  .with do |p|
	    p.id == 1 && p.url == "https://source/posts/1.json"
	  end
	  .returns(success(Post.new))

	status, mes, resp = @p.process!

	assert_equal :success, status, mes
	assert_nil mes
	refute_nil resp
      end

      context "when pool id is present" do
	setup do
	  @order.unstub(:pool_id)
	  @order.expects(:pool_id).returns(1)
	end

	should "fail if source pool doesn't exist" do
	  @client_to.expects(:get_pool).with(1).returns(failure)

	  status, mes, resp = @p.process!

	  assert_equal :failure, status, mes
	  assert_equal "could not find pool '1' in sink", mes
	  refute_nil resp
	end

	should "fail if post could not be added to pool" do
	  @client_to.expects(:get_pool).with(1).returns(success(Pool.new))
	  @client_to.expects(:upload_post)
	    .with do |p|
	      p.id == 1 && p.url == "https://source/posts/1.json"
	    end
	    .returns(success(Post.new))
	  @client_to.expects(:add_post_to_pool).returns(failure)

	  status, mes, resp = @p.process!

	  assert_equal :failure, status, mes
	  assert_equal "could not add post 'https://source/file.png' to pool '1' in sink", mes
	  refute_nil resp
	end

	should "succeed if post could be added to pool" do
	  @client_to.expects(:get_pool).with(1).returns(success(Pool.new))
	  @client_to.expects(:upload_post)
	    .with do |p|
	      p.id == 1 && p.url == "https://source/posts/1.json"
	    end
	    .returns(success(Post.new))
	  @client_to.expects(:add_post_to_pool).returns(success(Pool.new))

	  status, mes, resp = @p.process!

	  assert_equal :success, status, mes
	  assert_nil mes
	  refute_nil resp
	end
      end
    end

    context "when wiki page does not exist in sink" do
      setup do
	@client_to.expects(:find_wiki_page_by_name).returns(failure)
      end

      context "when tag does not exist in sink" do
	setup do
	  @client_to.expects(:find_tag_by_name).returns(failure)
	end

	should "fail if tag not found in source" do
	  @client_from.expects(:find_tag_by_name).returns(failure)

	  status, mes, resp = @p.process!

	  assert_equal :failure, status
	  assert_equal "could not find tag 'tag1' in source", mes
	  refute_nil resp
	end

	should "fail if tag creation fails" do
	  @client_from.expects(:find_tag_by_name).returns(success(Tag.new))
	  @client_to.expects(:create_tag).returns(failure)

	  status, mes, resp = @p.process!

	  assert_equal :failure, status
	  assert_equal "could not create tag 'tag1' in sink", mes
	  refute_nil resp
	end

	should "succeed if wiki page and tag creation succeed" do
	  @client_from.expects(:find_wiki_page_by_name).returns(success(WikiPage.new))
	  @client_to.expects(:create_wiki_page).returns(success(WikiPage.new))
	  @client_from.expects(:find_tag_by_name).returns(success(Tag.new))
	  @client_to.expects(:create_tag).returns(success(Tag.new))
	  @client_to.expects(:upload_post).returns(success(Post.new))

	  status, mes, resp = @p.process!

	  assert_equal :success, status, mes
	  assert_nil mes
	  refute_nil resp
	end

	should "continue if wiki page doesn't exist in source" do
	  @client_to.expects(:find_tag_by_name).returns(success(Tag.new))
	  @client_to.expects(:find_wiki_page_by_name).returns(failure)
	  @client_from.expects(:find_wiki_page_by_name).returns(failure)
	  @client_to.expects(:create_wiki_page).never
	  @client_to.expects(:upload_post).returns(success(Post.new))

	  status, mes, resp = @p.process!

	  assert_equal :success, status, mes
	  assert_nil mes
	  refute_nil resp
	end

	should "fail if wiki page creation fails" do
	  @client_to.expects(:find_tag_by_name).returns(success(Tag.new))
	  @client_to.expects(:find_wiki_page_by_name).returns(failure)
	  @client_from.expects(:find_wiki_page_by_name).returns(success(WikiPage.new))
	  @client_to.expects(:create_wiki_page).returns(failure)

	  status, mes, resp = @p.process!

	  assert_equal :failure, status
	  assert_equal "could not create wiki page 'tag1' in sink", mes
	  refute_nil resp
	end
      end

      context "when tag does exist in sink" do
	setup do
	  @client_to.expects(:find_tag_by_name).returns(success(Tag.new))
	end

	should "not try to create a new tag" do
	  @client_from.expects(:find_tag_by_name).never
	  @client_to.expects(:create_tag).never

	  @p.process!
	end
      end

      context "when wiki page does exist in sink" do
	setup do
	  @client_to.expects(:find_wiki_page_by_name).returns(success(WikiPage.new))
	end

	should "not try to create a new wiki page" do
	  @client_from.expects(:find_wiki_page_by_name).never
	  @client_to.expects(:create_wiki_page).never

	  @p.process!
	end
      end
    end
  end

  context "copy_wiki_page" do
    setup do
      order_for :wiki_page, 1
      wiki_page = WikiPage.new(url: "https://source/wiki_pages/1.json",
			       id: 1,
			       title: "title",
			       body: "body",
			       other_names: ["name"])
      @client_from.expects(:get_wiki_page).returns(success(wiki_page))
    end

    should "fail if wiki page creation fails" do
      @client_to.expects(:create_wiki_page).returns(failure)

      status, mes, resp = @p.process!

      assert_equal :failure, status
      assert_equal "could not create wiki page 'title' in sink", mes
      refute_nil resp
    end

    should "succeed if wiki page creation succeeds" do
      @client_to.expects(:create_wiki_page)
	.with do |w|
	w.title == "title" && w.body == "body"
      end
      .returns(success(WikiPage.new))

      status, mes, resp = @p.process!

      assert_equal :success, status
      assert_nil mes
      refute_nil resp
    end
  end

  context "copy_pool" do

    context "when pool has posts" do
      should "create orders for all posts in pool" do
      end
    end
  end
end
