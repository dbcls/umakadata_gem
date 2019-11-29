require 'umakadata/concerns/cacheable'
require 'umakadata/util/string'

module Umakadata
  module Criteria
    module Helpers
      module ValidityHelper
        include Cacheable
        include StringExt

        # @return [Umakadata::Activity]
        def non_http_uri_subject(**options)
          cache(key: options) do
            endpoint
              .sparql
              .select(:s)
              .where(%i[s p o])
              .filter(filter_for_non_http_subjects)
              .tap { |x| x.graph(:g) if endpoint.graph_keyword_supported? }
              .limit(1)
              .execute
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

            if resource_uri.uri.present?
              buffer.sub!('{ }', "{ VALUES ?s { <#{resource_uri.uri}> } { ?s owl:sameAs ?o . } UNION { ?s rdfs:seeAlso ?o . } }")
            else
              buffer.sub!('{ }', "{ { ?s owl:sameAs ?o . } UNION { ?s rdfs:seeAlso ?o . } FILTER(#{resource_uri.filter}) }")
            end

            endpoint.sparql.query(buffer).tap(&post_check_link_to_other_uri)
          end
        end

        private

        FILTER_HTTP_SUBJECTS = 'isURI(?s) && (STRSTARTS(str(?s), "http") || STRSTARTS(str(?s), "HTTP"))'.freeze

        def filter_for_non_http_subjects
          if endpoint.graph_keyword_supported?
            FILTER_HTTP_SUBJECTS + ' && ?g NOT IN (<http://www.openlinksw.com/schemas/virtrdf#>)'
          else
            FILTER_HTTP_SUBJECTS
          end
        end

        def post_non_http_uri_subject
          lambda do |activity|
            activity.type = Activity::Type::NON_HTTP_URI_SUBJECT

            activity.comment = if (r = activity.result).is_a?(::RDF::Query::Solutions)
                                 if r.count.zero?
                                   'Non HTTP(S) URI are not found.'
                                 else
                                   'Non HTTP(S) URI are found.'
                                 end
                               end
          end
        end

        def post_check_subject_uri
          lambda do |activity|
            activity.type = Activity::Type::NON_HTTP_URI_SUBJECT

            activity.comment = if (r = activity.result).is_a?(::RDF::Query::Solutions)
                                 if r.count.zero?
                                   'Non HTTP(S) URI are not found.'
                                 else
                                   'Non HTTP(S) URI are found.'
                                 end
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
