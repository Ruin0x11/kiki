require "set"
require "lib/adaptor"
require "base64"
require "faraday/param_part"
require "stringio"

class Client::PixivClient < Client::BaseClient
  attr_reader :conn

  API_VERSION = "1"
  CLIENT_ID = "bYGKuGVw91e0NMfPGp44euvGt59s"
  CLIENT_SECRET = "HP3RmkgAmEGro0gn1x9ioawQE8WMfvLXDz3ZqxpK"
  CLIENT_HASH_SALT = "28c1fdd170a5204386cb1313c7077b34f83e4aaf4aa829ce78c231e05b0bae2c"

  def initialize(domain, username, auth)
    super

    @conn = Faraday.new(url: "https://public-api.secure.pixiv.net/v#{API_VERSION}") do |faraday|
      faraday.headers["Referer"] = "http://www.pixiv.net"
      faraday.headers["Content-Type"] = "application/x-www-form-urlencoded"
      faraday.headers["Authorization"] = "Bearer #{access_token}"

      faraday.use Faraday::Request::Retry
      faraday.use Faraday::Response::Logger
      faraday.adapter Faraday::Adapter::NetHttp
    end
  end

  def parse_uri(uri)
    return {type: :post, id: illust_id(URI.parse(url))}
  end

  def has_wiki_pages?
    false
  end

  def has_pools?
    false
  end

  def get_post(id)
    r = @conn.get id

    url = (@conn.url_prefix + id).to_s

    Result.make(r) { |resp| Post.new(url: url,
				     id: 0,
				     source: url,
				     image_url: url,
				     tags: ["imported", "imported:image"],
				     rating: :s
				    ) }
  end

  def find_tag_by_name(name)
    Result.success(Tag.new(url: "", id: 0, name: name, category: "general"))
  end

  private

  # from danbooru
  MONIKER = %r!(?:[a-zA-Z0-9_-]+)!
  PROFILE = %r!\Ahttps?://www\.pixiv\.net/member\.php\?id=[0-9]+\z!
  DATE =    %r!(?<date>\d{4}/\d{2}/\d{2}/\d{2}/\d{2}/\d{2})!i
  EXT =     %r!(?:jpg|jpeg|png|gif)!i

  def illust_id(url)
    # http://www.pixiv.net/member_illust.php?mode=medium&illust_id=18557054
    # http://www.pixiv.net/member_illust.php?mode=big&illust_id=18557054
    # http://www.pixiv.net/member_illust.php?mode=manga&illust_id=18557054
    # http://www.pixiv.net/member_illust.php?mode=manga_big&illust_id=18557054&page=1
    if url.host == "www.pixiv.net" && url.path == "/member_illust.php" && url.query_values["illust_id"].present?
      return url.query_values["illust_id"].to_i

      # http://www.pixiv.net/en/artworks/46324488
    elsif url.host == "www.pixiv.net" && url.path =~ %r!\A/(?:en/)?artworks/(?<illust_id>\d+)!i
      return $~[:illust_id].to_i

      # http://www.pixiv.net/i/18557054
    elsif url.host == "www.pixiv.net" && url.path =~ %r!\A/i/(?<illust_id>\d+)\z!i
      return $~[:illust_id].to_i

      # http://img18.pixiv.net/img/evazion/14901720.png
      # http://i2.pixiv.net/img18/img/evazion/14901720.png
      # http://i2.pixiv.net/img18/img/evazion/14901720_m.png
      # http://i2.pixiv.net/img18/img/evazion/14901720_s.png
      # http://i1.pixiv.net/img07/img/pasirism/18557054_p1.png
      # http://i1.pixiv.net/img07/img/pasirism/18557054_big_p1.png
    elsif url.host =~ %r!\A(?:i\d+|img\d+)\.pixiv\.net\z!i &&
	url.path =~ %r!\A(?:/img\d+)?/img/#{MONIKER}/(?<illust_id>\d+)(?:_\w+)?\.(?:jpg|jpeg|png|gif|zip)!i
      return $~[:illust_id].to_i

      # http://i1.pixiv.net/img-inf/img/2011/05/01/23/28/04/18557054_64x64.jpg
      # http://i1.pixiv.net/img-inf/img/2011/05/01/23/28/04/18557054_s.png
      # http://i1.pixiv.net/c/600x600/img-master/img/2014/10/02/13/51/23/46304396_p0_master1200.jpg
      # http://i1.pixiv.net/img-original/img/2014/10/02/13/51/23/46304396_p0.png
      # http://i1.pixiv.net/img-zip-ugoira/img/2014/10/03/17/29/16/46323924_ugoira1920x1080.zip
      # https://i.pximg.net/img-original/img/2014/10/03/18/10/20/46324488_p0.png
      # https://i.pximg.net/img-master/img/2014/10/03/18/10/20/46324488_p0_master1200.jpg
      #
      # but not:
      #
      # https://i.pximg.net/novel-cover-original/img/2019/01/14/01/15/05/10617324_d84daae89092d96bbe66efafec136e42.jpg
      # https://img-sketch.pixiv.net/uploads/medium/file/4463372/8906921629213362989.jpg
    elsif url.host =~ %r!\A(?:i\.pximg\.net|i\d+\.pixiv\.net)\z!i &&
	url.path =~ %r!\A(/c/\w+)?/img-[a-z-]+/img/#{DATE}/(?<illust_id>\d+)(?:_\w+)?\.(?:jpg|jpeg|png|gif|zip)!i
      return $~[:illust_id].to_i
    end

    return nil
  end
end
