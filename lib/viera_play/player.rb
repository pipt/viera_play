require "curses"
require "streamio-ffmpeg"

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
    attr_reader :tv, :file_path, :server, :http_server_thread

    def exit
      tv.stop
      super
    end

    def video_duration
      @video_duration ||= TimeStamp.new(FFMPEG::Movie.new(file_path).duration.ceil)
    end

    def trap_interrupt
      trap 'INT' do
        trap 'INT', 'DEFAULT'
        exit
      end
    end

    def redraw
      info = tv.get_position_info

      win = Curses::Window.new(4, (Curses.cols - 2), Curses.lines/2 - 1, 1)
      @width = Curses.cols - 4
      win.clear
      win.box('|', '-', '+')
      win.setpos(1,1)
      win << '#' * (@width * info.position.to_i/(video_duration.to_i + 0.0001))
      win.setpos(2,1)
      win.addstr("%s of %s - %20s" % [info.position, video_duration, info.track])
      win.refresh

      exit if video_duration.to_i.zero?
    end

    def play_and_wait
      @http_server_thread = Thread.new { server.start }
      tv.play_uri(server.url)
      Curses.noecho
      Curses.init_screen
      Curses.stdscr.keypad(true) # enable arrow keys
      Curses.mousemask(Curses::BUTTON1_CLICKED)

      Curses.timeout = 1000

      redraw
      loop do
        c = Curses.getch
        case c
        when Curses::Key::LEFT
          tv.seek_by(-30)
        when Curses::Key::RIGHT
          tv.seek_by(30)
        when 'p', ' '
          tv.pause
        when 'q'
          exit
        when Curses::KEY_MOUSE
          if m = Curses.getmouse
            v = (m.x - 2).to_f / (@width) * video_duration.to_i
            tv.seek_to(v)
          end
        when nil
          redraw
        end
      end
    end
  end
end
