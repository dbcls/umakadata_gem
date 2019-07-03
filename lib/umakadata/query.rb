module Umakadata
  class Query
    attr_accessor :request
    attr_accessor :response

    attr_accessor :result

    attr_accessor :trace
    attr_accessor :warnings
    attr_accessor :errors

    def initialize
      @trace = []
      @warnings = []
      @errors = []
    end
  end
end
