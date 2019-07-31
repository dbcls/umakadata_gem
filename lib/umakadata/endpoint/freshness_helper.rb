module Umakadata
  class Endpoint
    module FreshnessHelper
      # @return [Array<Umakadata::Activity>]
      def number_of_statements(**options)
        cache(:number_of_statements, options) do
          [sparql
             .select(count: { '*' => :count })
             .where(%i[s p o])
             .tap { |x| x.graph(:g) if options[:graph] }
             .execute]
        end
      end

      # @return [Array<Umakadata::Activity>]
      def first_statement(**options)
        cache(:first_statement, options) do
          [sparql
             .construct(%i[s p o])
             .where(%i[s p o])
             .limit(1)
             .tap { |x| x.graph(:g) if options[:graph] }
             .execute]
        end
      end

      RETRY_LAST_STATEMENT = 3

      # @return [Array<Umakadata::Activity>]
      def last_statement(**options)
        cache(:last_statement, options) do
          act = Array(number_of_statements(**options))

          RETRY_LAST_STATEMENT.times do |t|
            break act unless (bindings = act.last&.result&.bindings)
            break act if (count = bindings[:count]&.first&.object).blank? || count.zero?

            act << sparql
                     .construct(%i[s p o])
                     .where(%i[s p o])
                     .limit(1)
                     .offset(count - 1)
                     .tap { |x| x.graph(:g) if options[:graph] }
                     .execute

            break act if act.last&.result.present? || t == (RETRY_LAST_STATEMENT - 1)

            cache[:number_of_statements][options] = nil
            act.push(*number_of_statements(**options))

            act
          end
        end
      end
    end
  end
end
