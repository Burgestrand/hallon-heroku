require 'bundler/setup'
require 'sinatra'
require 'spotify-heroku'
require 'hallon'

configure :production do
  set :appkey, open(ENV['HALLON_APPKEY']).read
  set :username, ENV['HALLON_USERNAME']
  set :password, ENV['HALLON_PASSWORD']
end

configure :development do
  require 'config'
  set :appkey, open(ENV['HALLON_APPKEY']).read
  set :username, ENV['HALLON_USERNAME']
  set :password, ENV['HALLON_PASSWORD']
end

configure do
  hallon = Hallon::Session.initialize(appkey)
  hallon.login!(username, password)
  set :hallon, hallon
end

get '/' do
  if hallon.logged_in?
    "Logged in as #{hallon.user.name}."
  else
    "Not logged in."
  end
end
