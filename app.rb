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

  def logged_in_text
    if hallon.logged_in?
      user = hallon.user.load
      "logged in as #{link_to user.name, user}"
    else
      "lot logged in"
    end
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
  @objects = [
    Hallon::Track.new("spotify:track:4d8EFwexIj2rtX4fIT2l8Q").load,
    Hallon::Artist.new("spotify:artist:6aZyMrc4doVtZyKNilOmwu").load,
    Hallon::Album.new("spotify:album:6cBZCIlOJCDC1Eh54aJDme").load,
    Hallon::User.new("burgestrand").load,
  ]

  erb :index
end

get '/redirect_to' do
  link = Hallon::Link.new(params[:spotify_uri])
  redirect to("/#{link.to_uri}"), :see_other
end

get uri_for(:profile) do |user|
  @user = Hallon::User.new(user).load
  @starred = @user.starred.load
  @starred_tracks = @starred.tracks[0, 20].map(&:load)
  erb :user
end

get uri_for(:track) do |track|
  @track  = Hallon::Track.new(track).load
  @artist = @track.artist.load
  @album  = @track.album.load
  @length = Time.at(@track.duration).gmtime.strftime("%M:%S")
  erb :track
end

get uri_for(:artist) do |artist|
  @artist    = Hallon::Artist.new(artist).load
  @browse    = @artist.browse.load
  @portraits = @browse.portrait_links.to_a
  @portrait  = @portraits.shift
  @tracks    = @browse.tracks[0, 20].map(&:load)
  @similar_artists = @browse.similar_artists.to_a
  @similar_artists.each(&:load)
  erb :artist
end

get uri_for(:album) do |album|
  @album  = Hallon::Album.new(album).load
  @browse = @album.browse.load
  @cover  = @album.cover_link
  @artist = @album.artist.load
  @tracks = @browse.tracks[0, 20].map(&:load)
  @review = @browse.review
  erb :album
end

get uri_for(:image) do |img|
  image = Hallon::Image.new(img).load
  headers "Content-Type" => "image/#{image.format}"
  image.data
end
