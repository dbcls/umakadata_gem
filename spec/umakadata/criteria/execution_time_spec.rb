require 'spec_helper'

describe 'Umakadata' do
  describe 'Criteria' do
    describe 'ExecutionTime' do

      describe '#execution_time' do
        MALFORMED_QUERY = <<-'SPARQL'
ASK{
SPARQL

        let(:test_class) { Struct.new(:target) { include Umakadata::Criteria::ExecutionTime } }
        let(:target) { test_class.new }

        before do
          @uri = URI("http://example.com")
        end

        it 'should return not nil' do
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::BASE_QUERY)
            .and_return(1000)
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::TARGET_QUERY)
            .and_return(10000)
          expect(target.execution_time(@uri)).not_to be_nil
          expect(target.get_error).to eq nil
        end

        it 'should return nil when the response time of ask query is nil' do
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::BASE_QUERY)
            .and_return(nil)
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::TARGET_QUERY)
            .and_return(10000)
          expect(target.execution_time(@uri)).to be_nil
        end

        it 'should return nil when the response time of target query is nil' do
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::BASE_QUERY)
            .and_return(1000)
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::TARGET_QUERY)
          .and_return(nil)
          expect(target.execution_time(@uri)).to be_nil
        end

        it 'should return nil when the response time of ask query is greater than the one of target query' do
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::BASE_QUERY)
            .and_return(10000)
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::TARGET_QUERY)
            .and_return(1000)
          expect(target.execution_time(@uri)).to eq (-9000)
        end

        it 'should return 9000 when the response time of ask query is 1000 and the one of target query is 10000' do
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::BASE_QUERY)
            .and_return(1000)
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::TARGET_QUERY)
            .and_return(10000)
          expect(target.execution_time(@uri)).to eq 9000
        end

        it 'should return 0 when the response time of ask query is 10000 and the one of target query is 10000' do
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::BASE_QUERY)
            .and_return(10000)
          allow(target).to receive(:response_time).with(Umakadata::Criteria::ExecutionTime::TARGET_QUERY)
            .and_return(10000)
          expect(target.execution_time(@uri)).to eq 0
        end

        describe '#response_time' do
          it 'should return nil when query is malformed' do
            target.instance_variable_set(:@uri, @uri)
            target.prepare(@uri)

            client = double('client')
            allow(client).to receive(:query).and_raise(SPARQL::Client::MalformedQuery, 'Occured MalformedQuery')
            target.set_client(client)

            expect(target.response_time(MALFORMED_QUERY)).to eq nil
            expect(target.get_error).to eq "Query: ASK{\n, Error: Occured MalformedQuery"
          end

          it 'should return time when query is correctly' do
           target.instance_variable_set(:@uri, @uri)
           target.prepare(@uri)

           client = double('client', :query => [])
           target.set_client(client)

           expect(target.response_time(Umakadata::Criteria::ExecutionTime::BASE_QUERY).instance_of?(Float)).to be true
           expect(target.response_time(Umakadata::Criteria::ExecutionTime::TARGET_QUERY).instance_of?(Float)).to be true
           expect(target.get_error).to eq nil
         end
       end

     end
    end
  end
end
