require "faraday"
require "mimemagic"
require "nokogiri"

def get_iqdb(data)
  @conn = Faraday.new(url: "https://www.iqdb.org") do |faraday|
    faraday.request :multipart

    faraday.use Faraday::Request::Retry
    faraday.use Faraday::Response::Logger
    faraday.adapter Faraday::Adapter::NetHttp
  end

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
  source = "https:" + source
  is_best = false
  th = page.at_css("th")
  if th and th.text.strip == "Best match"
    is_best = true
  end
  details = page.css("td")[2].text.strip.scan(/(\d+)×(\d+) \[(.+)\]/)[0]
  width = details[0].to_i
  height = details[1].to_i
  rating = details[2]
  similarity = page.css("td")[3].text.strip.scan(/(\d+)% similarity/)[0][0].to_i

  {
    source_type: source_type,
    source: source,
    is_best: is_best,
    width: width,
    height: height,
    rating: rating,
    similarity: similarity
  }
end

def parse_iqdb_response(body)
  doc = Nokogiri::HTML(body)
  pages = doc.at_css('div#pages')

  result = []

  best = pages.css("table")[1]
  result << parse_page(best)

  more = doc.at_css("div#more1 > .pages")
  if more
    more.css("table").each do |tbl|
      result << parse_page(tbl)
    end
  end

  result
end

def query_iqdb(file)
  resp = get_iqdb(file)
  raise "iqdb failed with status #{resp.status}" unless resp.status == 200
  File.write("./out.html", resp.body)
  parse_iqdb_response resp.body
end

pp query_iqdb(ENV["HOME"] + "/Pictures/wallhaven-g82533.jpg")

# resp = File.read("./out.html")
# pp parse_iqdb_response(resp)

