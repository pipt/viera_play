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

    def play_uri(uri)
      stop
      set_media_uri(uri)
      play
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
