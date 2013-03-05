# Viera Play

Viera Play uses DLNA to play video files on Panasonic Viera TVs from the
command line.

## Installation

Install it from Rubygems:

    $ gem install viera_play

Set your TV's control URL as the `TV_CONTROL_URL` environment variable
(using the IP of your TV):

    $ export TV_CONTROL_URL='http://192.168.0.2:55000/dmr/control_2'

## Usage

Run `viera_play` from the command line, giving it the path of a video
file to play:

    $ viera_play ~/my-video-file.mp4

`Control-C` will stop playback and shutdown the web server. The TV
remote can be used to pause/rewind/fast-foward the video as well.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
