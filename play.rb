#!/usr/bin/ruby

require "webrick"
require "socket"
require "net/http"
require "uri"

PORT = 8888

FORMATS = {
  ["mkv", "mp4", "wmv", "avi", "mov"] => "video/x-msvideo",
  ["mp3"] => "audio/mpeg"
}

TV_CONTROL_URL = "http://192.168.0.16:55000/dmr/control_2"

def local_ip
  UDPSocket.open do |s|
    s.connect '8.8.8.8', 1
    s.addr.last
  end
end

url_to_play = "http://#{local_ip}:#{PORT}/"

mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
FORMATS.each do |file_types, mime_type|
  file_types.each do |file_type|
    mime_types.store file_type, mime_type
  end
end

class FileServlet < WEBrick::HTTPServlet::DefaultFileHandler
  # Serves the given file_path no matter what is asked for
  def initialize(server, file_path)
    super(server, "/tmp")
    @local_path = file_path
  end
end

file_path = ARGV.first
server = WEBrick::HTTPServer.new(:Port => PORT, :MimeTypes => mime_types)
server.mount("/", FileServlet, file_path)

class TV
  def initialize(control_url)
    @control_url = control_url
  end

  def stop
    send_command("Stop")
  end

  def play
    send_command("Play", { "Speed" => "1" })
  end

  def set_media_uri(uri)
    send_command("SetAVTransportURI", "CurrentURI" => uri)
  end

private
  attr_reader :control_url

  def send_command(command, args={})
    default_args = {"InstanceID" => "0"}
    post(
      control_url,
      {
        "SOAPACTION" => %Q{"urn:schemas-upnp-org:service:AVTransport:1##{command}"},
        "Content-type" => "text/xml"
      },
      soap_body(command, default_args.merge(args))
    )
  end

  def post(url, headers, data)
    uri = URI.parse(url)
    Net::HTTP.new(uri.host, uri.port).post(uri.path, data, headers)
  end

  def soap_body(command, args)
    xml_args = args.map{ |key, value| "<#{key}>#{value}</#{key}>" }.join
    %Q{<?xml version="1.0"?>
      <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
        s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <s:Body>
          <u:#{command} xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            #{xml_args}
          </u:#{command}>
        </s:Body>
      </s:Envelope>}
  end
end

tv = TV.new(TV_CONTROL_URL)

trap 'INT' do
  tv.stop
  server.shutdown
end

pid = Process.fork do
  server.start
end

tv.stop
tv.set_media_uri(url_to_play)
tv.play

Process.wait(pid)
