require 'spec_helper'

describe 'Umakadata' do
  describe 'Criteria' do
    describe 'ContentNegotiation' do

      describe '#check_content_negotiation' do

        let(:test_class) { Struct.new(:target) { include Umakadata::Criteria::ContentNegotiation } }
        let(:target) { test_class.new }
        let(:allow_prefix) { 'http://exmaple.com/allowed' }
        let(:deny_prefix) { 'http://exmaple.com/denied' }
        let(:case_sensitive) { true }

        before do
          @uri = 'http://exmaple.com/'
          allow(Umakadata::SparqlHelper).to receive(:query).and_return([{ :s => @uri, :p => 'preidicate', :o => 'object' }])
        end

        it 'detect_ttl_support_if_response_is_ttl' do
          response = double(Net::HTTPResponse)
          allow(response).to receive(:content_type).and_return(Umakadata::DataFormat::TURTLE)
          allow(target).to receive(:http_head_recursive).and_return(response)
          allow(response).to receive(:is_a?).and_return(true)

          result = target.check_content_negotiation(@uri, allow_prefix, deny_prefix, case_sensitive, Umakadata::DataFormat::TURTLE)
          expect(result).to eq(true)
        end

        it 'detect_not_ttl_support_if_response_is_not_ttl' do
          response = double(Net::HTTPResponse)
          allow(response).to receive(:content_type).and_return(Umakadata::DataFormat::RDFXML)
          allow(target).to receive(:http_head_recursive).and_return(response)
          allow(response).to receive(:is_a?).and_return(true)

          result = target.check_content_negotiation(@uri, allow_prefix, deny_prefix, case_sensitive, Umakadata::DataFormat::TURTLE)
          expect(result).to eq(false)
        end

        it 'detect_rdfxml_support_if_response_is_rdfxml' do
          response = double(Net::HTTPResponse)
          allow(response).to receive(:content_type).and_return(Umakadata::DataFormat::RDFXML)
          allow(target).to receive(:http_head_recursive).and_return(response)
          allow(response).to receive(:is_a?).and_return(true)

          result = target.check_content_negotiation(@uri, allow_prefix, deny_prefix, case_sensitive, Umakadata::DataFormat::RDFXML)
          expect(result).to eq(true)
        end

        it 'detect_not_rdfxml_support_if_response_is_rdfxml' do
          response = double(Net::HTTPResponse)
          allow(response).to receive(:content_type).and_return(Umakadata::DataFormat::TURTLE)
          allow(target).to receive(:http_head_recursive).and_return(response)
          allow(response).to receive(:is_a?).and_return(true)

          result = target.check_content_negotiation(@uri, allow_prefix, deny_prefix, case_sensitive, Umakadata::DataFormat::RDFXML)
          expect(result).to eq(false)
        end

        it 'detect_html_support_if_response_is_html' do
          response = double(Net::HTTPResponse)
          allow(response).to receive(:content_type).and_return(Umakadata::DataFormat::HTML)
          allow(target).to receive(:http_head_recursive).and_return(response)
          allow(response).to receive(:is_a?).and_return(true)

          result = target.check_content_negotiation(@uri, allow_prefix, deny_prefix, case_sensitive, Umakadata::DataFormat::HTML)
          expect(result).to eq(true)
        end

        it 'detect_not_html_support_if_response_is_turtle' do
          response = double(Net::HTTPResponse)
          allow(response).to receive(:content_type).and_return(Umakadata::DataFormat::TURTLE)
          allow(target).to receive(:http_head_recursive).and_return(response)
          allow(response).to receive(:is_a?).and_return(true)

          result = target.check_content_negotiation(@uri, allow_prefix, deny_prefix, case_sensitive, Umakadata::DataFormat::HTML)
          expect(result).to eq(false)
        end

      end

      describe '#check_endpoint' do

        let(:test_class) { Struct.new(:target) { include Umakadata::Criteria::ContentNegotiation } }
        let(:target) { test_class.new }
        let(:client) { double(Umakadata::SparqlClient) }

        before do
          @uri = URI('http://example.com')
          allow(Umakadata::SparqlClient).to receive(:new).with(@uri, anything).and_return(client)
        end

        it 'detect_ttl_support_if_response_is_ttl' do
          response = double(RDF::Turtle::Reader)
          allow(client).to receive(:query).and_return(response)
          allow(response).to receive(:is_a?).with(RDF::Turtle::Reader).and_return(true)
          result = target.check_endpoint(@uri, Umakadata::DataFormat::TURTLE)
          expect(result).to eq(true)
        end

        it 'detect_not_ttl_support_if_response_is_not_ttl' do
          response = double(RDF::RDFXML::Reader)
          allow(client).to receive(:query).and_return(response)
          allow(response).to receive(:is_a?).with(RDF::Turtle::Reader).and_return(false)
          result = target.check_endpoint(@uri, Umakadata::DataFormat::TURTLE)
          expect(result).to eq(false)
        end

        it 'detect_rdfxml_support_if_response_is_rdfxml' do
          response = double(RDF::RDFXML::Reader)
          allow(client).to receive(:query).and_return(response)
          allow(response).to receive(:is_a?).with(RDF::RDFXML::Reader).and_return(true)
          result = target.check_endpoint(@uri, Umakadata::DataFormat::RDFXML)
          expect(result).to eq(true)
        end

        it 'detect_not_rdfxml_support_if_response_is_rdfxml' do
          response = double(RDF::Turtle::Reader)
          allow(client).to receive(:query).and_return(response)
          allow(response).to receive(:is_a?).with(RDF::RDFXML::Reader).and_return(false)
          result = target.check_endpoint(@uri, Umakadata::DataFormat::RDFXML)
          expect(result).to eq(false)
        end

        it 'detect_html_support_if_response_is_html' do
          response = double(Net::HTTPSuccess)
          allow(client).to receive(:query).and_return(response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:content_type).and_return(Umakadata::DataFormat::HTML)
          result = target.check_endpoint(@uri, Umakadata::DataFormat::HTML)
          expect(result).to eq(true)
        end

        it 'detect_not_html_support_if_response_is_turtle' do
          response = double(RDF::Turtle::Reader)
          allow(client).to receive(:query).and_return(response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(response).to receive(:content_type).and_return(Umakadata::DataFormat::TURTLE)
          result = target.check_endpoint(@uri, Umakadata::DataFormat::HTML)
          expect(result).to eq(false)
        end

        it 'detect_not_html_support_if_response_is_html_and_content_type_is_turtle' do
          response = double(Net::HTTPSuccess)
          allow(client).to receive(:query).and_return(response)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:content_type).and_return(Umakadata::DataFormat::TURTLE)
          result = target.check_endpoint(@uri, Umakadata::DataFormat::HTML)
          expect(result).to eq(false)
        end
      end
    end
  end
end
