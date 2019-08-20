require 'date'

module Umakadata
  class Criteria
    class Freshness < Criteria
      MEASUREMENT_NAMES = {
        last_updated: 'freshness.last_updated'
      }.freeze

      SOURCE_LAST_UPDATED = {
        service_description: 'Service Description',
        void: 'VoID'
      }.freeze

      # Obtain the date that the endpoint was updated
      #
      # @yield [measurement]
      # @yieldparam [Umakadata::Measurement]
      #
      # @return [String]
      def last_updated
        date = nil
        comment = 'No statements about update information found in either VoID or Service Description'

        %i[void service_description].each do |method|
          next unless (date = update_date(method))

          comment = "A statement about update information is found in #{SOURCE_LAST_UPDATED[method]}."
          break
        end

        measurement = Measurement.new(MEASUREMENT_NAMES[__method__], comment, [])

        yield measurement if block_given?

        inject_measurement(date&.utc&.to_s, measurement)
      end

      private

      module Query
        UPDATE_FROM_DESCRIPTION = RDF::Query.new do
          pattern [:s, RDF.type, RDF::Vocab::VOID[:DatasetDescription]]
          pattern [:s, RDF::Vocab::DC.modified, :date], optional: true
          pattern [:s, RDF::Vocab::DC.issued, :date], optional: true
        end

        UPDATE_FROM_DATASET = RDF::Query.new do
          pattern [:s, RDF.type, RDF::Vocab::VOID[:Dataset]]
          pattern [:s, RDF::Vocab::DC.modified, :date], optional: true
          pattern [:s, RDF::Vocab::DC.issued, :date], optional: true
        end
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
      # @return [Array<RDF::Literal>]
      def extract_update_date(method)
        statements = endpoint.send(method).first.result
        return [] unless statements.present?

        dataset = RDF::Dataset.new(statements: statements)

        Array(dataset.query(Query::UPDATE_FROM_DESCRIPTION).bindings[:date])
          .concat(Array(dataset.query(Query::UPDATE_FROM_DATASET).bindings[:date]))
      end
    end
  end
end
