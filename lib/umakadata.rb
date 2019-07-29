require 'faraday'
require 'linkeddata'

require 'faraday/response_ext'
require 'rdf/enumerable_ext'
require 'rdf/statement_ext'

# Namespace for Umakadata
module Umakadata
  require 'umakadata/activity'
  require 'umakadata/criteria'
  require 'umakadata/endpoint'
  require 'umakadata/http'
  require 'umakadata/logger'
  require 'umakadata/measurement'
  require 'umakadata/sparql'
  require 'umakadata/version'
end
