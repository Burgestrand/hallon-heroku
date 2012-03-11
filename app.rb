require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?

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
  $hallon ||= begin
    require 'hallon'
    appkey = IO.read('./bin/spotify_appkey.key')
    Hallon.load_timeout = 10
    Hallon::Session.initialize(appkey).tap do |hallon|
      hallon.login!(ENV['HALLON_USERNAME'], ENV['HALLON_PASSWORD'])
    end
  end

  set :hallon, $hallon
end

helpers do
  def hallon
    Hallon::Session.instance
  end

  def link_to(text, object)
    link = object.to_link
    %Q{<a class="#{link.type}" href="/#{link.to_uri}">#{text}</a>}
  end

  def image_to(image_link)
    %Q{<img src="/#{image_link.to_str}" class="#{image_link.type}">}
  end
end

at_exit do
  if Hallon::Session.instance?
    hallon = Hallon::Session.instance
    hallon.logout!
  end
end

def uri_for(type)
  lambda do |uri|
    uri = uri.sub(%r{\A/}, '')
    return unless Hallon::Link.valid?(uri)
    return unless Hallon::Link.new(uri).type == type
    Hallon::URI.match(uri)
  end.tap do |matcher|
    matcher.singleton_class.send(:alias_method, :match, :call)
  end
end

error Hallon::TimeoutError do
  status 504
  body "Hallon timed out."
end

get '/' do
  if hallon.logged_in?
    "Logged in as #{hallon.user.name}."
  else
    "Not logged in."
  end
end

get uri_for(:track) do |uri|
  @track  = Hallon::Track.new(uri).load
  @artist = @track.artist.load
  @album  = @track.album.load
  @length = Time.at(@track.duration).gmtime.strftime("%M:%S")
  erb :track
end

get uri_for(:artist) do |uri|
  @artist    = Hallon::Artist.new(uri).load
  @browse    = @artist.browse.load
  @portraits = @browse.portrait_links.to_a
  @portrait  = @portraits.shift
  @tracks    = @browse.tracks[0, 20].map(&:load)
  @similar_artists = @browse.similar_artists.to_a
  @similar_artists.each(&:load)
  erb :artist
end

get uri_for(:image) do |img|
  image = Hallon::Image.new(img).load
  headers "Content-Type" => "image/#{image.format}"
  image.data
end
