class Kiki < Sinatra::Base
  post "/order" do
    if ["url"].any? { |s| !params.key?(s) || params[s].empty? }
      halt 400, "FAILED Missing required parameters\n"
    end

    url = params["url"]
    # session_token = params["session_token"]

    # user = User.from_session(session_token)
    user = User.find_by_name("ruin")
    halt 400, "BADSESSION\n" if user.nil?

    server_from = Server.find_matching(url)
    server_to = Server.find_matching("http://megucabooru.nori.dev")

    halt 400, "FAILED Bad server\n" if server_from.nil? or server_to.nil?

    order = Order.create(user: user,
			 server_from: server_from,
			 server_to: server_to,
			 url: url,
			 finished: false)

    halt 400, "FAILED Order: #{order.errors.full_messages.join(",")}\n" unless order.valid?

    "OK\n"
  end
end
