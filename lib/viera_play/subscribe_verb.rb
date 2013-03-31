module VieraPlay
  class SubscribeVerb < Net::HTTPRequest
    METHOD = "SUBSCRIBE"
    REQUEST_HAS_BODY = true
    RESPONSE_HAS_BODY = true
  end
end
