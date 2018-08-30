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
        end

        it 'should return void object when valid response is retrieved of n3 format' do
          valid_n3 = read_file('good_n3_01.n3')
          response = double(Net::HTTPResponse)
          allow(target).to receive(:http_get_recursive).with(@uri, anything, logger: nil).and_return(response)
          allow(target).to receive(:well_known_uri).and_return(@uri)
          allow(response).to receive(:is_a?).and_return(true)
          allow(response).to receive(:body).and_return(valid_n3)

          void = target.void_on_well_known_uri(@uri)

          expect(!void.nil?).to be true
          expect(!void.text.nil?).to be true
          expect(void.license.include?('http://creativecommons.org/licenses/by/2.1/jp/')).to be false
          expect(void.publisher.include?('http://www.example.org/Publisher')).to be false
        end

        it 'should return void object when valid response is retrieved of n-triples format' do
          valid_ntriples = read_file('good_ntriples_01.nt')
          response = double(Net::HTTPResponse)
          allow(target).to receive(:http_get_recursive).with(@uri, anything, logger: nil).and_return(response)
          allow(target).to receive(:well_known_uri).and_return(@uri)
          allow(response).to receive(:is_a?).and_return(true)
          allow(response).to receive(:body).and_return(valid_ntriples)

          void = target.void_on_well_known_uri(@uri)

          expect(void.license.include?('http://creativecommons.org/licenses/by/2.1/jp/')).to be true
          expect(void.publisher.include?('http://www.example.org/Publisher')).to be true
        end

        it 'should return void object when valid response is retrieved of RDFa format' do
          valid_rdfa = read_file('good_rdfa_01.html')
          response = double(Net::HTTPResponse)
          allow(target).to receive(:http_get_recursive).with(@uri, anything, logger: nil).and_return(response)
          allow(target).to receive(:well_known_uri).and_return(@uri)
          allow(response).to receive(:is_a?).and_return(true)
          allow(response).to receive(:body).and_return(valid_rdfa)

          void = target.void_on_well_known_uri(@uri)

          expect(void.license.include?('http://creativecommons.org/licenses/by/2.1/jp/')).to be true
          expect(void.publisher.include?('http://www.example.org/Publisher')).to be true
        end

        it 'should return void object when valid response is retrieved of html format with json-ld' do
          valid_jsonld = read_file('good_jsonld_01.html')
          response = double(Net::HTTPResponse)
          allow(target).to receive(:http_get_recursive).with(@uri, anything, logger: nil).and_return(response)
          allow(target).to receive(:well_known_uri).and_return(@uri)
          allow(response).to receive(:is_a?).and_return(true)
          allow(response).to receive(:body).and_return(valid_jsonld)
          allow(response).to receive(:content_type).and_return(Umakadata::DataFormat::HTML)

          void = target.void_on_well_known_uri(@uri)

          expect(void.license.include?('http://creativecommons.org/licenses/by/2.1/jp/')).to be true
          expect(void.publisher.include?('http://www.example.org/Publisher')).to be true
        end

        it 'should return void object when valid response is retrieved of json-ld format' do
          valid_jsonld = read_file('good_jsonld_02.jsonld')
          response     = double(Net::HTTPResponse)
          allow(target).to receive(:http_get_recursive).with(@uri, anything, logger: nil).and_return(response)
          allow(target).to receive(:well_known_uri).and_return(@uri)
          allow(response).to receive(:is_a?).and_return(true)
          allow(response).to receive(:body).and_return(valid_jsonld)
          allow(response).to receive(:content_type).and_return(Umakadata::DataFormat::HTML)

          void = target.void_on_well_known_uri(@uri)

          expect(void.license.include?('http://creativecommons.org/licenses/by/2.1/jp/')).to be true
          expect(void.publisher.include?('http://www.example.org/Publisher')).to be true
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
        end

        it 'should return false descriotion object when invalid response of html format is retrieved' do
          invalid_html = read_file('bad_jsonld_01.html')
          response = double(Net::HTTPSuccess)
          allow(target).to receive(:http_get_recursive).with(@uri, anything, logger: nil).and_return(response)
          allow(target).to receive(:well_known_uri).and_return(@uri)
          allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(response).to receive(:body).and_return(invalid_html)

          void = target.void_on_well_known_uri(@uri)

          expect(void.text).to be_nil
          expect(void.license).to be_nil
          expect(void.publisher).to be_nil
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
