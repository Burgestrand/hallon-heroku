require 'bundler/setup'
require 'sinatra'

configure :production do
  require 'spotify-heroku'
end

configure :development do
  begin
    require 'config'
  rescue LoadError
    abort "You must supply your credentials, either through config.rb or the environment"
  end unless ENV['HALLON_USERNAME'] and ENV['HALLON_PASSWORD']
end

configure do
  require 'hallon'
  appkey = IO.read('./bin/spotify_appkey.key')
  hallon = Hallon::Session.initialize(appkey, settings_path: "tmp/settings", cache_path: "tmp/spotifycache")
  hallon.login!(ENV['HALLON_USERNAME'], ENV['HALLON_PASSWORD'])
  set :hallon, hallon
end

helpers do
  def hallon
    Hallon::Session.instance
  end
end

at_exit do
  if Hallon::Session.instance?
    hallon = Hallon::Session.instance
    hallon.logout!
  end
end

get '/' do
  if hallon.logged_in?
    "Logged in as #{hallon.user.name}."
  else
    "Not logged in."
  end
end
