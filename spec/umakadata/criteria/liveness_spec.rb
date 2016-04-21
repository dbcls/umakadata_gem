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

        it 'should return true when the response code is 200' do
          allow(target).to receive(:http_get).with(@uri, nil, 10)
            .and_return(Net::HTTPOK.new('1.1', '200', 'OK'))
          expect(target.alive?(@uri, 10)).to be true
        end

        it 'should return false when the response code is 404' do
          allow(target).to receive(:http_get).with(@uri, nil, 10)
            .and_return(Net::HTTPNotFound.new('1.1', '404', 'Not Found'))
          expect(target.alive?(@uri, 10)).to be false
        end

      end
    end
  end
end
