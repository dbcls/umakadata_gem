require 'spec_helper'

describe 'Umakadata' do
  describe 'Criteria' do
    describe 'Liveness' do

      describe '#alive?' do

        let(:test_class) { Struct.new(:target) { include Umakadata::Criteria::Liveness } }
        let(:target) { test_class.new }

        before do
          @uri = URI('http://example.com')
        end

        it 'should return true when Net::HTTP.get_response returns Net::HTTPSuccess' do
          response = double(Net::HTTPResponse)
          allow(response).to receive(:is_a?).and_return(true)
          allow(target).to receive(:http_get).and_return(response)
          expect(target.alive?(@uri, 10)).to be true
        end

        it 'should return true when Net::HTTP.get_response does not return Net::HTTPSuccess and Net::HTTP.post_form returns Net::HTTPSuccess' do
          response_get = double(Net::HTTPResponse)
          allow(response_get).to receive(:is_a?).and_return(false)
          allow(target).to receive(:http_get).and_return(response_get)

          response_post = double(Net::HTTPResponse)
          allow(response_post).to receive(:is_a?).and_return(true)
          allow(target).to receive(:http_post).and_return(response_post)

          expect(target.alive?(@uri, 10)).to be true
        end

        it 'should return false when Net::HTTP.get_response does not return Net::HTTPSuccess and Net::HTTP.post_form does not return Net::HTTPSuccess' do
          response_get = double(Net::HTTPResponse)
          allow(response_get).to receive(:is_a?).and_return(false)
          allow(target).to receive(:http_get).and_return(response_get)

          response_post = double(Net::HTTPResponse)
          allow(response_post).to receive(:is_a?).and_return(false)
          allow(target).to receive(:http_post).and_return(response_post)

          expect(target.alive?(@uri, 10)).to be false
        end

      end
    end
  end
end
