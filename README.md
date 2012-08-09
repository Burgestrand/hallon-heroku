# This is an example project…
It uses [Hallon](https://github.com/Burgestrand/Hallon), [libspotify](http://developer.spotify.com/en/libspotify/overview/) (through Hallon)
and [Sinatra](http://www.sinatrarb.com/). What it does is that it logs in to Spotify on startup, and then tells you if it’s logged in or not
on start page.

It also allows you to browse objects pointed to by Spotify URIs. All pages have a "Go to" box that allows you to paste in a Spotify URI to
view details about it.

## How to get it running
You’ll need your Spotify Premium Account credentials and a [Spotify Application Key](https://developer.spotify.com/technologies/libspotify/keys/).
Now, put all your credentials in your environment variables:

    export HALLON_USERNAME='your_username'
    export HALLON_PASSWORD='your_password'

Your application key needs special consideration, since it may contain special characters. It needs to
be encoded into base64 before putting it in the environment variable. Luckily, there is a ruby script
in `bin/serialize_appkey.rb` that will do this for you.

    export HALLON_APPKEY="$(ruby bin/serialize_appkey.rb /path/to/appkey.rb)"

After this, you’ll want to download the dependencies:

- Ruby 1.9.2+
- [Bundler](http://gembundler.com/)

Finally, install all gems required for your platform by using bundler.

    bundle install

Now, you should have all dependencies.

## Running it on Heroku
Create an application on Heroku, push the application to it, add your Spotify credentials:

    heroku config:add HALLON_USERNAME='your_username'
    heroku config:add HALLON_PASSWORD='your_password'
    heroku config:add HALLON_APPKEY="$(ruby bin/serialize_appkey.rb /path/to/appkey.rb)"

That’s all there should be to it. Now open it with `heroku open`!

## Running it locally

    foreman start

Done. Open it in your browser on `http://localhost:5000`.
