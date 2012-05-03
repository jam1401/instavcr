require "vcr"
enable :sessions

CALLBACK_URL = "http://localhost:9393/oauth/callback"

Instagram.configure do |config|
  config.client_id = CLIENT_ID
  config.client_secret = CLIENT_SECRET
end

VCR.configure do |c|
    c.cassette_library_dir = 'fixtures/vcr_cassettes'
    c.hook_into :faraday, :webmock
#    c.configure_rspec_metadata!
    c.allow_http_connections_when_no_cassette = true

    oauth_match = VCR.request_matchers.uri_without_param(:oauth_timestamp, :oauth_nonce, :oauth_signature)

    c.register_request_matcher(:oauth, &oauth_match)

    c.ignore_localhost = true
end

get "/" do
  puts "In Index"
  '<a href="/oauth/connect">Connect with Instagram</a>'
end

get "/oauth/connect" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL, :scope => 'comments relationships likes')
end

get "/oauth/callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response.access_token
  redirect "/feed"
end

get "/feed" do
  client = Instagram.client(:access_token => session[:access_token])
  user = client.user
  VCR.use_cassette('instafail', :record => :new_episodes) do
  html = "<h1>#{user.username}'s recent photos</h1>"
  recent_media = client.user_recent_media
  for media_item in recent_media
    html << "<img src='#{media_item.images.thumbnail.url}'>"
  end
  html
  end
end

get "/access_token" do
  'access_token: ' + session[:access_token]
end

