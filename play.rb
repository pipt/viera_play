#!/usr/bin/ruby

require "webrick"
require "socket"
require "net/http"
require "uri"

class SingleFileServer
  def initialize(file_path, additional_mime_types)
    @file_path = file_path
    @additional_mime_types = FORMATS.merge(additional_mime_types)
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

  FORMATS = {
    ["mkv", "mp4", "wmv", "avi", "mov"] => "video/x-msvideo",
    ["mp3"] => "audio/mpeg"
  }

  def mime_types
    mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
    additional_mime_types.each do |file_types, mime_type|
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

class Player
  def initialize(opts)
    @tv = TV.new(opts.fetch(:tv_control_url))
    @file_path = opts.fetch(:file_path)
    @server = SingleFileServer.new(file_path, opts.fetch(:additional_mime_types, {}))
  end

  def call
    trap_interrupt
    play_and_wait
  end

private
  attr_reader :tv, :file_path, :server

  def trap_interrupt
    trap 'INT' do
      tv.stop
      server.shutdown
    end
  end

  def play_and_wait
    http_server_thread = Thread.new do
      server.start
    end

    tv.play_uri(server.url)
    http_server_thread.join
  end
end

Player.new(
  :tv_control_url => "http://192.168.0.16:55000/dmr/control_2",
  :file_path => ARGV.first
).call
