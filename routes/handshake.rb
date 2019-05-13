class Kiki < Sinatra::Base
  SUPPORTED_PROTOCOLS = ['1.2', '1.2.1']

  post '/login' do
    if !["username", "token", "timestamp"].all? { |s| params.key?(s) }
      halt 400, "Missing required fields\n"
    end

    username = params["username"]
    token = params["token"]
    timestamp = params["timestamp"].to_i

    if timestamp - Time.now.to_i > 300
      halt 400, "Timestamp in the future\n"
    end

    p timestamp
    is_authorized = check_auth(username, auth_token, timestamp)

    user = User.find_by_name(username)
    if user.nil?
      halt 400, "User not found\n"
    end

    if user.password != password
      halt 400, "Not authorized\n"
    end

    user_id = user.id
    session_id = BCrypt::Password.create(auth_token + Time.now.to_i.to_s)

    Session.create(id: user_id.to_s, sessionid: session_id, expires: Time.now.to_i + 24.hours.to_i)

    "OK\n#{session_id}"
  end
end
