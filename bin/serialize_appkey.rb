#!/usr/bin/env ruby
# encoding: utf-8
#
# Given a spotify appkey, it will be serialized into it’s hexadecimal form.
# If you want to add your appkey to an environment variable it will not be
# possible because the appkey might contain null bytes, but in hexadecimal
# form you can!
#
# Assuming you set the ENV['SPOTIFY_APPKEY'] to your application key, you
# can read it out in a form that Hallon can use with this snippet:
#
#   appkey = Base64.decode64(ENV['SPOTIFY_APPKEY'])
require 'base64'

ARGF.set_encoding 'BINARY'

puts Base64.encode64(ARGF.read)
