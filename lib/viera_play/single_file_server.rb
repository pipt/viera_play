require "webrick"
require "socket"

module VieraPlay
  class SingleFileServer
    def initialize(file_path, additional_mime_types={}, source_ip = '8.8.8.8')
      @file_path = file_path
      @additional_mime_types = FORMATS.merge(additional_mime_types)
      @source_ip = source_ip
    end

    def start
      server.start
    end

    def shutdown
      server.shutdown
    end

    def url
      "http://#{local_ip}:#{port}/"
    end

    private
    attr_reader :file_path, :additional_mime_types, :source_ip

    FORMATS = {
      ["mkv"] => "video/x-matroska",
      ["mp4", "wmv", "avi", "mov"] => "video/x-msvideo",
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
      @server ||= WEBrick::HTTPServer.new(
        :Port => port,
        :MimeTypes => mime_types,
        :DocumentRoot => file_path
      )
    end

    def port
      8888
    end

    def local_ip
      @local_ip ||= UDPSocket.open do |s|
        s.connect source_ip, 1
        s.addr.last
      end
    end
  end
end
