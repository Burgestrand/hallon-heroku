#!/usr/bin/env ruby
# encoding: utf-8
#
# Encodes a Spotify application key into base64 for safe usage in environment
# variables. This is needed because the application key usually contain null
# bytes, and those cannot be put in environment variables on many systems.
#
# Assuming you set the ENV['SPOTIFY_APPKEY'] to your application key, you
# can read it out in a form that Hallon can use with this snippet:
#
#   require 'base64'
#   appkey = Base64.decode64(ENV['SPOTIFY_APPKEY'])
require 'base64'

ARGF.set_encoding 'BINARY'

puts Base64.encode64(ARGF.read)
