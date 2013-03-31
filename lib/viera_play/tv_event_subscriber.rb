require "webrick"
require "net/http"
require "nokogiri"

module VieraPlay
  class TvEventSubscriber
    def initialize
      @server = WEBrick::HTTPServer.new(:Port => 1234)
      Thread.new { @server.start }
      @server.mount("/notify", NotifyServlet, self)
      sleep 1
      http = Net::HTTP.new("192.168.0.16", "55000")
      request = SubscribeVerb.new("/dmr/event_2")
      request["CALLBACK"] = "<http://#{local_ip}:1234/notify>"
      request["NT"] = "upnp:event"
      p request.each.to_a
      p http.request(request).each.to_a
    end

    def local_ip
      @local_ip ||= UDPSocket.open do |s|
        s.connect '8.8.8.8', 1
        s.addr.last
      end
    end

    def call(last_change)
      p last_change
    end
  end
end

class NotifyServlet < WEBrick::HTTPServlet::AbstractServlet
  def initialize(server, callback)
    super(server)
    @callback = callback
  end

  def do_NOTIFY(request, response)
    doc = Nokogiri::XML(request.body)
    last_change = Nokogiri::XML(doc.css('LastChange').first.content)
    callback.call(last_change)
  end

private
  attr_reader :callback
end
