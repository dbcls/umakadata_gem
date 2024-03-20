require 'umakadata/concerns/cacheable'
require 'umakadata/util/string'

module Umakadata
  module Criteria
    module Helpers
      module ValidityHelper
        include Cacheable
        include StringExt

        # @return [Umakadata::Activity]
        def http_uri_subject(resource_uri)
          cache(key: resource_uri) do
            buffer = endpoint
                       .sparql
                       .select
                       .where
                       .tap { |x| x.graph(:g) if endpoint.graph_keyword_supported? }
                       .limit(1)
                       .to_s

            if resource_uri.uri.present?
              buffer.sub!('{ }', "{ VALUES ?s { <#{resource_uri.uri}> } { ?s ?p ?o . } }")
            else
              buffer.sub!('{ }', "{ { ?s ?p ?o . } FILTER(#{resource_uri.filter}) }")
            end

            endpoint.sparql.query(buffer).tap(&post_http_uri_subject)
          end
        end

        # @return [Umakadata::Activity]
        def non_http_uri_subject(**options)
          cache(key: options) do
            filter_string = "!(#{SUBJECT_REJECT.map { |x| "STRSTARTS(str(?s), \"#{x}\")" }.join(' || ')}) && " \
              "(#{SUBJECT_ACCEPT.map { |x| "STRSTARTS(str(?s), \"#{x}\")" }.join(' || ')})"

            query = endpoint
                      .sparql
                      .select(:s)
                      .where(%i[s p o])
                      .tap { |x| x.graph(:g) if endpoint.graph_keyword_supported? }
                      .filter(filter_string)
                      .limit(10)
                      .to_s

            if endpoint.graph_keyword_supported?
              query = query.sub('} LIMIT', 'FILTER(?g NOT IN (<http://www.openlinksw.com/schemas/virtrdf#>)) } LIMIT')
            end

            endpoint.query(query)
                    .tap(&post_non_http_uri_subject)
          end
        end

        # @return [Umakadata::Activity]
        def check_link_to_other_uri(resource_uri)
          cache(key: resource_uri) do
            buffer = endpoint
                       .sparql
                       .select
                       .where
                       .tap { |x| x.graph(:g) if endpoint.graph_keyword_supported? }
                       .limit(1)
                       .prefix(rdfs: ::RDF::Vocab::RDFS, owl: ::RDF::Vocab::OWL)
                       .to_s

            buffer = buffer.sub('{ }') do
              if resource_uri.uri.present?
                "{ VALUES ?s { <#{resource_uri.uri}> } { ?s owl:sameAs ?o . } UNION { ?s rdfs:seeAlso ?o . } }"
              else
                "{ { ?s owl:sameAs ?o . } UNION { ?s rdfs:seeAlso ?o . } FILTER(#{resource_uri.filter}) }"
              end
            end

            endpoint.sparql.query(buffer).tap(&post_check_link_to_other_uri)
          end
        end

        private

        SUBJECT_REJECT = %w[http://www.openlinksw.com/ http://www.w3.org/ http://xmlns.com/]
        SUBJECT_ACCEPT = %w[http HTTP]

        def post_http_uri_subject
          lambda do |activity|
            activity.type = Activity::Type::RETRIEVE_URI
            activity.comment = if (r = activity.result).is_a?(::RDF::Query::Solutions) && r.count.positive?
                                 'An URI found by SPARQL query.'
                               else
                                 'Failed to obtain URIs by SPARQL query.'
                               end
          end
        end

        def post_non_http_uri_subject
          lambda do |activity|
            activity.type = Activity::Type::NON_HTTP_URI_SUBJECT

            activity.comment = if (r = activity.result).is_a?(::RDF::Query::Solutions) && r.count.positive?
                                 "#{r.count} HTTP(S) #{'subject'.pluralize(r.count)} found."
                               else
                                 'No HTTP(S) subjects found.'
                               end
          end
        end

        def post_check_link_to_other_uri
          lambda do |activity|
            activity.type = Activity::Type::LINK_TO_OTHER_URI

            activity.comment = if (r = activity.result).is_a?(::RDF::Query::Solutions)
                                 if r.count.positive?
                                   "#{r.first.bindings[:s]} has link to other URI."
                                 else
                                   'No links to other URI are found.'
                                 end
                               end
          end
        end
      end
    end
  end
end
