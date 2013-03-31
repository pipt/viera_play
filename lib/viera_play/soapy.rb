require "net/http"
require "uri"

module VieraPlay
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
      response = Net::HTTP.new(endpoint.host, endpoint.port).post(
        endpoint.path,
        data,
        headers
      )
      response.body
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
end
