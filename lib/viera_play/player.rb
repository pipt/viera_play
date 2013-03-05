module VieraPlay
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
      http_server_thread = Thread.new { server.start }
      tv.play_uri(server.url)
      http_server_thread.join
    end
  end
end
