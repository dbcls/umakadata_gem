require 'faraday'

module Faraday
  class Response
    # @return [String]
    def content_type
      headers['Content-Type']
    end
  end
end
