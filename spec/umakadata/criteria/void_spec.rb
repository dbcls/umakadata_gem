require 'spec_helper'

describe 'Umakadata' do
  describe 'Criteria' do
    describe 'VoID' do

      describe '#void_on_well_known_uri' do

        let(:test_class) { Struct.new(:target) { include Umakadata::Criteria::VoID } }
        let(:target) { test_class.new }

        before do
          @uri = URI('http://example.com/.well-known/void')
        end

        def read_file(file_name)
          cwd = File.expand_path('../../../data/umakadata/criteria/void', __FILE__)
          File.open(File.join(cwd, file_name)) do |file|
            file.read
          end
        end

        it 'should return void object when valid response is retrieved of ttl format' do
          valid_ttl = read_file('good_turtle_01.ttl')
          response = double(Net::HTTPResponse)
          allow(target).to receive(:http_get_recursive).with(@uri, anything, logger: nil).and_return(response)
          allow(target).to receive(:well_known_uri).and_return(@uri)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:each_key)
          allow(response).to receive(:body).and_return(valid_ttl)

          void = target.void_on_well_known_uri(@uri)

          expect(void.license.include?('http://creativecommons.org/licenses/by/2.1/jp/')).to be true
          expect(void.publisher.include?('http://www.example.org/Publisher')).to be true
          expect(void.modified).to eq Time.parse("2016-01-01 10:00:00")
        end

        it 'should return void object when valid response is retrieved of xml format' do
          valid_ttl = read_file('good_xml_01.xml')
          response = double(Net::HTTPResponse)
          allow(target).to receive(:http_get_recursive).with(@uri, anything, logger: nil).and_return(response)
          allow(target).to receive(:well_known_uri).and_return(@uri)
          allow(response).to receive(:is_a?).and_return(true)
          allow(response).to receive(:body).and_return(valid_ttl)

          void = target.void_on_well_known_uri(@uri)

          expect(void.license.include?('http://creativecommons.org/licenses/by/2.1/jp/')).to be true
          expect(void.publisher.include?('http://www.example.org/Publisher')).to be true
          expect(void.modified).to eq Time.parse("2016-01-01 10:00:00")
        end

        it 'should return false description object when invalid response is retrieved' do
          invalid_ttl = read_file('bad_turtle_01.ttl')
          response = double(Net::HTTPSuccess)
          allow(target).to receive(:http_get_recursive).with(@uri, anything, logger: nil).and_return(response)
          allow(target).to receive(:well_known_uri).and_return(@uri)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(invalid_ttl)

          void = target.void_on_well_known_uri(@uri)

          expect(void.text).to be_nil
          expect(void.license).to be_nil
          expect(void.publisher).to be_nil
          expect(void.modified).to be_nil
        end

        it 'should set error message when invalid response is retrieved' do
          response = double(Net::HTTPInternalServerError)
          allow(target).to receive(:http_get_recursive).with(@uri, anything, logger: nil).and_return(response)
          allow(target).to receive(:well_known_uri).and_return(@uri)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(response).to receive(:is_a?).with(Net::HTTPResponse).and_return(true)
          allow(response).to receive(:code).and_return('500')
          allow(response).to receive(:message).and_return('Internal Server Error')

          void = target.void_on_well_known_uri(@uri)

          expect(void).to be_nil
        end

      end
    end
  end
end
