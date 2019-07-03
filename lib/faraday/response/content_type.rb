require 'faraday'

module Faraday
  class Response
    def content_type
      headers['Content-Type']
    end
  end
end
