require "viera_play/single_file_server"
require "viera_play/tv"
require "viera_play/soapy"
require "viera_play/player"

VieraPlay::Player.new(
  :tv_control_url => "http://192.168.0.16:55000/dmr/control_2",
  :file_path => ARGV.first
).call
