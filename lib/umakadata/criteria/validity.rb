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
        subject_uri_provides_information: 'validity.subject_uri_provides_information',
        provide_useful_information: 'validity.provide_useful_information',
        link_to_other_uri: 'validity.links_to_other_uri'
      }.freeze

      #
      # @return [Umakadata::Measurement]
      def cool_uri
        Measurement.new do |m|
          score, comments = cool_uri_score
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = score
          m.comment = "Cool URI score is #{score}\n" + comments.map { |x| "- #{x}" }.join("\n")
        end
      end

      # @return [Umakadata::Measurement]
      def http_uri
        activity = non_http_uri_subject

        Measurement.new do |m|
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = (r = activity.result).is_a?(RDF::Query::Solutions) && r.count.zero?
          m.comment = if m.value
                        'All subjects are URI or blank node.'
                      elsif r.is_a?(RDF::Query::Solutions) && r.count.positive?
                        'Some subjects are not HTTP(S) URI.'
                      else
                        'Failed to evaluate result.'
                      end
          m.activities = [activity]
        end
      end

      # @return [Umakadata::Measurement]
      def provide_useful_information
        content_negotiate(ResourceURI::NegotiationTypes::ANY, MEASUREMENT_NAMES[__method__]) do |m|
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = m.activities.any? { |act| act.response&.status == 200 }
          m.comment = "The endpoint #{m.value ? 'provides' : 'does not provide'} useful information "\
                      'by looking up a URI.'
        end
      end

      # @return [Umakadata::Measurement]
      def link_to_other_uri
        activities = []

        endpoint.resource_uri.each do |p|
          activities.push(check_link_to_other_uri(p))
        end

        Measurement.new do |m|
          m.name = MEASUREMENT_NAMES[__method__]
          m.value = m.activities.any? { |act| (r = act.result).is_a?(RDF::Query::Solutions) && r.count.positive? }
          m.comment = "The endpoint #{m.value ? 'has' : 'does not have'} links to other URIs."
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
    end
  end
end
