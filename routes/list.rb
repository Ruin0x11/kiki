class Kiki < Sinatra::Base
  get "/list" do
    logger.info "test"

    s = ""

    Order.all.each do |o|
      s = s + "<div>#{o.id} #{o.url} #{o.status}</div>\n"
    end

    s
  end
end
