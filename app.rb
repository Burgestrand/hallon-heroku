require 'bundler/setup'
require 'base64'
require 'sinatra'
require 'sinatra/reloader' if development?

unless "".respond_to?(:try)
  class Object
    alias_method :try, :send
  end

  class NilClass
    def try(*)
    end
  end
end

class ConfigurationError < StandardError
end

def env(varname)
  ENV.fetch(varname) do
    raise ConfigurationError, "Missing ENV['#{varname}']."
  end
end

configure do
  $hallon ||= begin
    require 'hallon'
    Hallon.load_timeout = 10

    appkey = Base64.decode64(env('HALLON_APPKEY'))
    Hallon::Session.initialize(appkey).tap do |hallon|
      hallon.login!(env('HALLON_USERNAME'), env('HALLON_PASSWORD'))
    end
  end

  set :hallon, $hallon

  # Allow iframing
  disable :protection
end

helpers do
  def hallon
    Hallon::Session.instance
  end

  def link_to(text, object = text)
    link = object
    link = link.to_link if link.respond_to?(:to_link)
    href = link.try(:to_str)
    type = link.try(:type)
    %Q{<a class="#{type}" href="/#{object.to_str}">#{text}</a>}
  end

  def image_to(image_link)
    link_to %Q{<img src="/#{image_link.to_str}" class="#{image_link.type}">}, image_link
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
  @links = [
    Hallon::Link.new("spotify:track:4d8EFwexIj2rtX4fIT2l8Q"),
    Hallon::Link.new("spotify:artist:6aZyMrc4doVtZyKNilOmwu"),
    Hallon::Link.new("spotify:album:6cBZCIlOJCDC1Eh54aJDme"),
    Hallon::Link.new("spotify:user:burgestrand"),
    Hallon::Link.new("spotify:user:burgestrand:playlist:5BwQBlDoZVoNnDItvO2IUb")
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

get uri_for(:playlist) do |playlist|
  @playlist = Hallon::Playlist.new(playlist).load
  @playlist.update_subscribers
  @owner    = @playlist.owner.load
  @tracks   = @playlist.tracks.to_a
  @tracks.each(&:load)
  erb :playlist
end
