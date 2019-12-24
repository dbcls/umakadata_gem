require 'date'
require 'umakadata/criteria/base'
require 'umakadata/rdf/vocabulary'

module Umakadata
  module Criteria
    class Freshness < Base
      MEASUREMENT_NAMES = {
        last_updated: 'freshness.last_updated'
      }.freeze

      SOURCE_LAST_UPDATED = {
        service_description: 'Service Description',
        void: 'VoID'
      }.freeze

      def measurements
        MEASUREMENT_NAMES.keys.map { |x| method(x) }
      end

      # Obtain the date that the endpoint was updated
      #
      # @return [Umakadata::Measurement]
      def last_updated
        Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
          date = nil
          comment = 'No statements about update information found in either VoID or Service Description'

          %i[void service_description].each do |method|
            next unless (date = update_date(method))

            comment = "A statement about update information is found in #{SOURCE_LAST_UPDATED[method]}."
            break
          end

          m.value = date if date.is_a?(Date)
          m.comment = comment
        end
      end

      private

      module Query
        DATASET_TYPES = %W[<#{::RDF::Vocab::VOID[:Dataset]}>
                           <#{::RDF::Vocab::VOID[:DatasetDescription]}>
                           <#{RDF::Vocabulary::SSD[:Dataset]}>
                           <#{RDF::Vocabulary::SSD[:Graph]}>].freeze

        UPDATE = SPARQL::Client::Query.select(:date)
                   .where([:s, ::RDF.type, :type])
                   .where([:s, :p, :date])
                   .filter("?type IN (#{DATASET_TYPES.join(', ')})")
                   .filter("?p IN (<#{::RDF::Vocab::DC.modified}>, <#{::RDF::Vocab::DC.issued}>)")
      end

      # @param [Symbol] method :void or :service_description
      # @return [DateTime, nil]
      def update_date(method)
        date = extract_update_date(method)

        begin
          date.map { |x| DateTime.parse(x.value) }.max
        rescue StandardError
          nil
        end
      end

      # @param [Symbol] method :void or :service_description
      # @return [Array<RDF::Term>]
      def extract_update_date(method)
        statements = endpoint.send(method).result
        return [] unless statements.present?

        dataset = ::RDF::Dataset.new(statements: statements)

        dataset.query(::SPARQL::Grammar.parse(Query::UPDATE)).bindings[:date] || []
      end
    end
  end
end
