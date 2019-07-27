require 'linkeddata'

require_relative 'faraday/response/content_type'
require_relative 'rdf/statement_improve'

# Namespace for Umakadata
module Umakadata
  require 'umakadata/endpoint'
  require 'umakadata/http'
  require 'umakadata/logger'
  require 'umakadata/query'
  require 'umakadata/sparql'
  require 'umakadata/version'
end
