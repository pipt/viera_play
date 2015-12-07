module VieraPlay
  class Player
    def initialize(opts)
      uri = URI(opts.fetch(:tv_control_url))
      @tv = TV.new(uri)
      @file_path = opts.fetch(:file_path)
      @server = SingleFileServer.new(file_path, opts.fetch(:additional_mime_types, {}), uri.host)
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
      http_server_thread = Thread.new { server.start }
      tv.play_uri(server.url)
      http_server_thread.join
    end
  end
end
