require 'faraday'
require 'linkeddata'

require 'faraday/response_ext'
require 'rdf/blank_node'
require 'rdf/enumerable_ext'
require 'rdf/statement_ext'
require 'sparql/client/query_ext'

# Namespace for Umakadata
module Umakadata
  require 'umakadata/configuration'
  require 'umakadata/crawler'
  require 'umakadata/criteria'
  require 'umakadata/endpoint'
  require 'umakadata/http'
  require 'umakadata/logger'
  require 'umakadata/models'
  require 'umakadata/sparql'
  require 'umakadata/version'
end
