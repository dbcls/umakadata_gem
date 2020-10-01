require 'umakadata/criteria/base'
require 'umakadata/criteria/helpers/content_negotiation_helper'
require 'umakadata/criteria/helpers/validity_helper'
require 'resolv'

module Umakadata
  module Criteria
    class Validity < Base
      include Helpers::ContentNegotiationHelper
      include Helpers::ValidityHelper

      MEASUREMENT_NAMES = {
        cool_uri: 'validity.cool_uri',
        http_uri: 'validity.http_uri',
        provide_useful_information: 'validity.provide_useful_information',
        link_to_other_uri: 'validity.link_to_other_uri'
      }.freeze

      def measurements
        MEASUREMENT_NAMES.keys.map { |x| method(x) }
      end

      #
      # @return [Umakadata::Measurement]
      def cool_uri
        Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
          score, comments = cool_uri_score
          m.value = score
          m.comment = "Cool URI score is #{score}\n" + comments.map { |x| "- #{x}" }.join("\n")
        end
      end

      # @return [Umakadata::Measurement]
      def http_uri
        Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
          activities = []

          if provide_useful_information&.value == true
            m.value = true
            m.comment = 'HTTP URI are found by checking `URI provides useful information?`'
          else
            endpoint.resource_uri.each do |p|
              activities.push((activity = http_uri_subject(p)))
              next unless (r = activity.result).is_a?(::RDF::Query::Solutions) && r.count.positive?

              m.value = true
              m.comment = 'HTTP URI are found.'
            end

            unless m.value
              activities.push((activity = non_http_uri_subject))

              m.value = (r = activity.result).is_a?(::RDF::Query::Solutions) && r.count == 10
              m.comment = if m.value
                            'HTTP(S) URI are found.'
                          elsif r.is_a?(::RDF::Query::Solutions) && r.count.positive?
                            'HTTP(S) URI are found but not enough to evaluate.'
                          else
                            'No HTTP(S) URIs found.'
                          end
            end
          end

          m.activities = activities
        end
      end

      # @return [Umakadata::Measurement]
      def provide_useful_information
        if endpoint.resource_uri.blank?
          return Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
            m.comment = 'The endpoint does not have indexed URI.'
          end
        end

        negotiations = {
          ResourceURI::NegotiationTypes::HTML => endpoint.usefulness.support_html_format,
          ResourceURI::NegotiationTypes::TURTLE => endpoint.usefulness.support_rdfxml_format,
          ResourceURI::NegotiationTypes::RDFXML => endpoint.usefulness.support_turtle_format
        }

        if (formats = negotiations.select { |_, v| v.value == true }).present?
          Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
            m.value = true
            m.comment = 'The endpoint supports content negotiation for ' + formats.keys.to_sentence
          end
        elsif (formats = negotiations.select { |_, v| v.activities.any?(&body_not_empty?) }).present?
          Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
            m.value = true
            m.comment = 'The endpoint returns some contents for ' + formats.keys.to_sentence
          end
        else
          Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
            m.value = false
            m.comment = 'The endpoint does not provide useful information.'
          end
        end
      end

      # @return [Umakadata::Measurement]
      def link_to_other_uri
        Umakadata::Measurement.new(name: MEASUREMENT_NAMES[__method__]).safe do |m|
          activities = []

          endpoint.resource_uri.each do |p|
            activities.push(check_link_to_other_uri(p))
          end

          m.value = activities.any? { |act| (r = act.result).is_a?(::RDF::Query::Solutions) && r.count.positive? }
          m.comment = if endpoint.resource_uri.blank?
                        'The endpoint does not have indexed URI.'
                      else
                        "The endpoint #{m.value ? 'has' : 'does not have'} links to other URIs."
                      end
          m.activities = activities
        end
      end

      private

      def cool_uri_score
        score = 0
        comments = []

        score += score_host_name(comments)
        score += score_port(comments)
        score += score_parameter(comments)
        score += score_length(comments)

        [score, comments]
      end

      def score_host_name(comments)
        url = ::URI.parse(endpoint.url)

        if url.hostname&.match?(Resolv::IPv4::Regex)
          comments << 'The host of the endpoint URL matches IPv4 regular expression pattern. (+0)'
          0
        elsif url.hostname&.match?(Resolv::IPv6::Regex)
          comments << 'The host of the endpoint URL matches IPv6 regular expression pattern. (+0)'
          0
        else
          comments << 'The host of the endpoint URL is not specified by IP address. (+25)'
          25
        end
      end

      def score_port(comments)
        if endpoint.url.match(%r{https?://[^/:]+(:\d+)?}).captures.compact.present?
          comments << 'The endpoint URL contains port number. (+0)'
          0
        else
          comments << 'The endpoint URL does not contain port number. (+25)'
          25
        end
      end

      def score_parameter(comments)
        if ::URI.parse(endpoint.url).query.blank?
          comments << 'The endpoint URL does not contain query parameters. (+25)'
          25
        else
          comments << 'The endpoint URL contains query parameters. (+0)'
          0
        end
      end

      def score_length(comments)
        if ::URI.parse(endpoint.url).to_s.length <= (l = 30)
          comments << "The length of the endpoint URL is less than #{l} characters. (+25)"
          25
        else
          comments << "The length of the endpoint URL is more than #{l} characters. (+0)"
          0
        end
      end

      def body_not_empty?
        lambda do |act|
          act.type.to_s.match?('content_negotiation_') &&
            act.response&.status == 200 &&
            act.response&.body&.size&.positive?
        end
      end
    end
  end
end
