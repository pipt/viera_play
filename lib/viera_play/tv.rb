require "nokogiri"
require "viera_play/time_stamp"
module VieraPlay
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

    def pause
      send_command("Pause")
    end

    def play
      send_command("Play", "Speed" => "1")
    end

    def seek_by(ammount)
      info = get_position_info
      seek_to(info.position + ammount)
    end

    def seek_to(position)
      target = TimeStamp.new(position)
      send_command(
        "Seek",
        "Unit" => 'REL_TIME',
        "Target" => target
      )
    end

    def play_uri(uri)
      stop
      set_media_uri(uri)
      play
    end

    class PositionInfo
      def initialize(xml)
        @doc = Nokogiri::XML(xml)
      end

      def position
        TimeStamp.parse @doc.css('RelTime').first.content
      end

      def track
        sub_doc = @doc.css('TrackMetaData').first.content
        parsed_subdoc = Nokogiri::XML(sub_doc)
        titles = parsed_subdoc.xpath(
          '//dc:title',
          'dc' => 'http://purl.org/dc/elements/1.1/'
        )
        if titles.empty?
          ""
        else
          first.content
        end
      end
    end

    # Gets playback status information from the host. Returns a PositionInfo
    # instance.
    def get_position_info
      response = send_command("GetPositionInfo")
      PositionInfo.new response.body
    end

  private
    attr_reader :soap_client

    def set_media_uri(uri)
      send_command(
        "SetAVTransportURI",
        "CurrentURI" => uri,
        "CurrentURIMetaData" => ""
      )
    end

    def send_command(command, args={})
      soap_client.send_command(command, args)
    end
  end
end
