require 'spec_helper'
require 'umakadata/criteria/filter_clause'

module Umakadata
  module Criteria
    describe 'FilterClause' do
      describe '#filter_clause' do
        let(:test_class) { Struct.new(:dummy_struct) { include Umakadata::Criteria::FilterClause } }
        let(:target) { test_class.new }

        context 'if only allow_prefix is present' do
          it 'should return filter with case_sensitive positive regex' do
            expected = 'FILTER (regex(str(?s), "^http://allowed_prefix.com"))'
            expect(target.filter_clause('http://allowed_prefix.com', nil, true)).to eq(expected)
          end

          it 'should return filter with case_insensitive positive regex' do
            expected = 'FILTER (regex(str(?s), "^http://allowed_prefix.com", "i"))'
            expect(target.filter_clause('http://allowed_prefix.com', nil, false)).to eq(expected)
          end
        end

        context 'if only deny_prefix is present' do
          it 'should return filter with case_sensitive negative regex filter' do
            expected = 'FILTER (!regex(str(?s), "^http://denied_prefix.com"))'
            expect(target.filter_clause(nil, 'http://denied_prefix.com', true)).to eq(expected)
          end

          it 'should return filter with case_insensitive negative regex filter' do
            expected = 'FILTER (!regex(str(?s), "^http://denied_prefix.com", "i"))'
            expect(target.filter_clause(nil, 'http://denied_prefix.com', false)).to eq(expected)
          end
        end

        context 'if both allow_prefix and deny_prefix are present' do
          it 'should return filter with case_sensitive positive and negative regex filter' do
            expected = 'FILTER (regex(str(?s), "^http://allowed_prefix.com") AND !regex(str(?s), "^http://denied_prefix.com"))'
            expect(target.filter_clause('http://allowed_prefix.com', 'http://denied_prefix.com', true)).to eq(expected)
          end

          it 'should return filter with case_insensitive negative regex filter' do
            expected = 'FILTER (regex(str(?s), "^http://allowed_prefix.com", "i") AND !regex(str(?s), "^http://denied_prefix.com", "i"))'
            expect(target.filter_clause('http://allowed_prefix.com', 'http://denied_prefix.com', false)).to eq(expected)
          end
        end


        context 'if neither allow_prefix nor deny_prefix is present' do
          it 'should raise StandardError' do
            expect{ target.filter_clause(nil, nil, false) }.to raise_exception(StandardError)
          end
        end
      end
    end
  end
end
