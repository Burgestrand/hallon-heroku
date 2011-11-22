#
# Source: https://github.com/Burgestrand/Hallon/blob/master/spec/mockspotify.rb
#
# Note: Make sure “libspotify.so” is in the same directory as you place this file
#       in; otherwise the library will not be found.
require 'ffi'

module Spotify
  module Heroku
    # @return [String] path to the libmockspotify C extension binary.
    def self.libspotify_path
      File.expand_path('../bin/libspotify.so', __FILE__)
    end

    # Overridden to always ffi_lib the right path.
    def ffi_lib(*)
      super(Spotify::Heroku.libspotify_path)
    end
  end

  # extend FFI::Library first, so when Spotify extends FFI::Library,
  # it will not override our Heroku#ffi_lib method
  extend FFI::Library

  # now bring in Heroku#ffi_lib method that overrides FFI::Library#ffi_lib,
  # so when Spotify tries to bind to libspotify, it binds to the one we tell
  # it to bind to
  extend Spotify::Heroku

  # finally, we bring in spotify!
  require 'spotify'
end
