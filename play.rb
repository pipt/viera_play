#!/usr/bin/ruby

require "webrick"
require "socket"
require "net/http"
require "uri"

FORMATS = {
  ["mkv", "mp4", "wmv", "avi", "mov"] => "video/x-msvideo",
  ["mp3"] => "audio/mpeg"
}

TV_CONTROL_URL = "http://192.168.0.16:55000/dmr/control_2"

file_path = ARGV.first

class SingleFileServer
  def initialize(file_path, additional_mime_types)
    @file_path = file_path
    @additional_mime_types = additional_mime_types
  end

  def start
    server.mount("/", FileServlet, file_path)
    server.start
  end

  def shutdown
    server.shutdown
  end

  def url
    "http://#{local_ip}:#{port}/"
  end

private
  attr_reader :file_path, :additional_mime_types

  def mime_types
    mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
    FORMATS.each do |file_types, mime_type|
      file_types.each do |file_type|
        mime_types.store file_type, mime_type
      end
    end
    mime_types
  end

  def server
    @server ||= WEBrick::HTTPServer.new(:Port => port, :MimeTypes => mime_types)
  end

  def port
    8888
  end

  def local_ip
    @local_ip ||= UDPSocket.open do |s|
      s.connect '8.8.8.8', 1
      s.addr.last
    end
  end

  class FileServlet < WEBrick::HTTPServlet::DefaultFileHandler
    # Serves the given file_path no matter what is asked for
    def initialize(server, file_path)
      super(server, "/tmp")
      @local_path = file_path
    end
  end
end

class TV
  def initialize(control_url)
    @soap_client = Soapy.new(
      :endpoint => control_url,
      :namespace => "urn:schemas-upnp-org:service:AVTransport:1",
      :default_request_args => {"InstanceID" => "0"}
    )
  end

  def stop
    send_command("Stop")
  end

  def play
    send_command("Play", "Speed" => "1")
  end

  def play_uri(uri)
    stop
    set_media_uri(uri)
    play
  end

private
  attr_reader :soap_client

  def set_media_uri(uri)
    send_command("SetAVTransportURI", "CurrentURI" => uri)
  end

  def send_command(command, args={})
    soap_client.send_command(command, args)
  end
end

class Soapy
  def initialize(opts={})
    @endpoint = URI.parse(opts.fetch(:endpoint))
    @namespace = opts.fetch(:namespace)
    @default_request_args = opts.fetch(:default_request_args, {})
  end

  def send_command(command, args={})
    post(
      {
        "SOAPACTION" => %Q{"#{namespace}##{command}"},
        "Content-type" => "text/xml"
      },
      soap_body(command, default_request_args.merge(args))
    )
  end

private
  attr_reader :endpoint, :namespace, :default_request_args

  def post(headers, data)
    Net::HTTP.new(endpoint.host, endpoint.port).post(endpoint.path, data, headers)
  end

  def soap_body(command, args)
    xml_args = args.map{ |key, value| "<#{key}>#{value}</#{key}>" }.join
    %Q{<?xml version="1.0"?>
      <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
        s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <s:Body>
          <u:#{command} xmlns:u="#{namespace}">
            #{xml_args}
          </u:#{command}>
        </s:Body>
      </s:Envelope>}
  end
end

tv = TV.new(TV_CONTROL_URL)

server = SingleFileServer.new(ARGV.first, FORMATS)

trap 'INT' do
  tv.stop
  server.shutdown
end

http_server_thread = Thread.new do
  server.start
end

tv.play_uri(server.url)

http_server_thread.join
