# -*- coding: utf-8 -*-
require "test_helper"

require "client"

class Client::Danbooru2ClientTest < BaseTest
  def setup
    @client = Client::Danbooru2Client.new "https://danbooru.donmai.us", "ruin", "auth"
  end

  def setup_response(fixture, url)
    body = read_fixture(fixture)

    env = stub
    env.stubs(:url).returns("the_url")

    response = stub
    response.stubs(:success?).returns(true)
    response.stubs(:body).at_least_once.returns(body)
    response.stubs(:env).returns(env)
    @client.conn.expects(:get).with(url).returns(response)
  end

  def setup_failure_response(url)
    response = stub
    response.stubs(:success?).returns(false)
    @client.conn.expects(:get).with(url).returns(response)
  end

  def setup_request(fixture, url, req)
    body = read_fixture(fixture)

    env = stub
    env.stubs(:url).returns("the_url")

    response = stub
    response.stubs(:success?).returns(true)
    response.stubs(:body).at_least_once.returns(body)
    response.stubs(:env).returns(env)
    @client.conn.expects(:post).with(url, req).returns(response)
  end

  def test_parse_uri
    res = @client.parse_uri("https://danbooru.donmai.us/posts/2234129")
    assert_equal :post, res[:type]
    assert_equal 2234129, res[:id]
  end

  def test_parse_uri_2
    res = @client.parse_uri("https://danbooru.donmai.us/posts/3477823/")
    assert_equal :post, res[:type]
    assert_equal 3477823, res[:id]
  end

  def test_get_post
    setup_response "danbooru2/post.json", "/posts/1077187.json"

    post = @client.get_post(1077187)

    assert_equal 1077187, post.id
    assert_equal "the_url", post.url
    assert_equal "http://img04.pixiv.net/img/syounen_no_uta/24425315.jpg", post.source
    assert_equal "https://raikou2.donmai.us/f6/fe/f6fe71488d890586afda9ee610f103c9.jpg", post.image_url
    assert_equal 32, post.tags.length
    assert_instance_of String, post.tags.first
    assert_equal :s, post.rating
  end

  def test_get_post_failure
    setup_failure_response "/posts/1.json"

    post = @client.get_post(1)

    assert_equal false, post.success?
  end

  def test_get_wiki_page
    setup_response "danbooru2/wiki_page.json", "/wiki_pages/32524.json"

    wiki_page = @client.get_wiki_page(32524)

    assert_equal 32524, wiki_page.id
    assert_equal "the_url", wiki_page.url
    assert_equal "kiki", wiki_page.title
    assert_equal 246, wiki_page.body.length
    assert_equal ["キキ"], wiki_page.other_names
  end

  def test_get_tag
    setup_response "danbooru2/tag.json", "/tags/4579.json"

    tag = @client.get_tag(4579)

    assert_equal 4579, tag.id
    assert_equal "the_url", tag.url
    assert_equal "kiki", tag.name
    assert_equal :character, tag.category
  end

  def test_get_pool
    setup_response "danbooru2/pool.json", "/pools/3780.json"

    pool = @client.get_pool(3780)

    assert_equal 3780, pool.id
    assert_equal "the_url", pool.url
    assert_equal "Your Shipment Has Arrived", pool.name
    assert_equal "collection", pool.category
    assert_equal 93, pool.description.length
    assert_equal 170, pool.post_ids.length
    assert_instance_of Integer, pool.post_ids.first
  end

  def test_upload_post
    expected = {
      "source" => "https://source/file.png",
      "tag_string" => "tag1 tag2 tag3",
      "rating" => "s"
    }
    setup_request "danbooru2/upload.json", "/uploads.json", expected

    post = Post.new(id: 1,
		    url: "https://source/posts/1",
		    source: "https://source/file.png",
		    tags: ["tag1", "tag2", "tag3"],
		    rating: :s,
		    parent_id: nil)

    upload = @client.upload_post(post)

    assert_equal true, upload.success?
    assert_equal "the_url", upload.url
    assert_equal 1, upload.id
    assert_equal "http://img04.pixiv.net/img/syounen_no_uta/24425315.jpg", upload.source
    assert_equal ["1girl", "amazon_(company)", "imported", "imported:danbooru"], upload.tags
    assert_equal :s, upload.rating
  end

  def test_upload_post_parent_id
    expected = {
      "source" => "https://source/file.png",
      "tag_string" => "tag1 tag2 tag3",
      "rating" => "s",
      "parent_id" => 1
    }
    setup_request "danbooru2/upload.json", "/uploads.json", expected

    post = Post.new(id: 2,
		    url: "https://source/posts/1",
		    source: "https://source/file.png",
		    tags: ["tag1", "tag2", "tag3"],
		    rating: :s,
		    parent_id: 1)

    upload = @client.upload_post(post)

    assert_equal "the_url", upload.url
    assert_equal 1, upload.id
    assert_equal "http://img04.pixiv.net/img/syounen_no_uta/24425315.jpg", upload.source
    assert_equal ["1girl", "amazon_(company)", "imported", "imported:danbooru"], upload.tags
    assert_equal :s, upload.rating
  end

  def test_create_wiki_page
    expected = {
      "title" => "The Title",
      "body" => "body\n\n(Kiki metadata - Source|https://source/wiki_pages/1)",
      "other_names" => "name1 name2"
    }
    setup_request "danbooru2/wiki_page.json", "/wiki_pages.json", expected

    wiki_page = WikiPage.new(id: 1,
			     url: "https://source/wiki_pages/1",
			     title: "The Title",
			     body: "body",
			     other_names: ["name1", "name2"])

    result = @client.create_wiki_page(wiki_page)

    assert_equal 32524, result.id
  end
end
