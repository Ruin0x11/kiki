# coding: utf-8
require "faraday"
require "mimemagic"
require "nokogiri"

IQDBResult = Struct.new :source_type,
			:source,
			:is_best,
			:width,
			:height,
			:rating,
			:similarity,
			keyword_init: true

class IQDBClient
  def initialize(url)
    @conn = Faraday.new(url: url) do |faraday|
      faraday.request :multipart

      faraday.use Faraday::Request::Retry
      faraday.use Faraday::Response::Logger
      faraday.adapter Faraday::Adapter::NetHttp
    end
  end

  def query(file)
    resp = get(file)
    raise "IQDB query failed with status #{resp.status}" unless resp.status == 200
    parse_iqdb_response resp.body
  end

  private

  def get(data)
    mime = if String === data
	     MimeMagic.by_path(data)
	   else
	     MimeMagic.by_magic(data)
	   end

    file_part = Faraday::FilePart.new(data, mime.to_s)

    payload = { file: file_part }

    @conn.post('/', payload)
  end

  def parse_page(page)
    source_type = page.css("td")[1].children[1].text.strip
    source = page.at_css("a")[:href]
    source = URI.parse(source)
    if source.scheme == nil
      source.scheme = "https"
    end
    is_best = false
    th = page.at_css("th")
    if th and th.text.strip == "Best match"
      is_best = true
    end
    pp page.css("td")[2]
    details = page.css("td")[2].text.strip

    parsed = details.scan(/(\d+)×(\d+) \[(.+)\]/)[0]
    if parsed
      width = parsed[0].to_i
      height = parsed[1].to_i
      rating = parsed[2]
    else
      parsed = details.scan(/\[(.+)\]/)[0]
      width = 0
      height = 0
      rating = parsed[0]
    end
    similarity = page.css("td")[3].text.strip.scan(/(\d+)% similarity/)[0][0].to_i

    IQDBResult.new(
      source_type: source_type,
      source: source,
      is_best: is_best,
      width: width,
      height: height,
      rating: rating,
      similarity: similarity
    )
  end

  def parse_iqdb_response(body)
    doc = Nokogiri::HTML(body)
    pages = doc.at_css('div#pages')

    result = []

    best = pages.css("table")[1]
    return [] if best.at_css("th").text == "No relevant matches"

    result << parse_page(best)

    more = doc.at_css("div#more1 > .pages")
    if more
      more.css("table").each do |tbl|
	result << parse_page(tbl)
      end
    end

    result
  end
end
