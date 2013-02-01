require "webrick"
require "socket"

PORT = 8888

FORMATS = {
  ["mkv", "mp4", "wmv", "avi", "mov"] => "video/x-msvideo",
  ["mp3"] => "audio/mpeg"
}

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

def stop
  `curl -H 'SOAPACTION: "urn:schemas-upnp-org:service:AVTransport:1#Stop"' -X POST -H 'Content-type: text/xml' -d '<?xml version="1.0"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Stop xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID></u:Stop></s:Body></s:Envelope>' 192.168.0.16:55000/dmr/control_2`
end

def play
  `curl -H 'SOAPACTION: "urn:schemas-upnp-org:service:AVTransport:1#Play"' -X POST -H 'Content-type: text/xml' -d '<?xml version="1.0"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><Speed>1</Speed></u:Play></s:Body></s:Envelope>' 192.168.0.16:55000/dmr/control_2`
end

trap 'INT' do
  stop
  server.shutdown
end

pid = Process.fork do
  server.start
end

stop
`curl -H 'SOAPACTION: "urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI"' -X POST -H 'Content-type: text/xml' -d '<?xml version="1.0"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">  <s:Body>    <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">      <InstanceID>0</InstanceID>      <CurrentURI>#{url_to_play}</CurrentURI>      <CurrentURIMetaData></CurrentURIMetaData>    </u:SetAVTransportURI>  </s:Body></s:Envelope>' 192.168.0.16:55000/dmr/control_2`
play

Process.wait(pid)
