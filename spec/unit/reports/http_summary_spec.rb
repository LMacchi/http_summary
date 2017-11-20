require 'spec_helper'
require 'puppet/reports'

http_summary = Puppet::Reports.report(:http_summary)

describe http_summary do
  let(:unchanged) do
    f = my_fixture 'report_unchanged.yaml'
    YAML.load File.new(f, 'r')
  end
  let(:changed) do
    f = my_fixture 'report_changed.yaml'
    YAML.load File.new(f, 'r')
  end

  let(:http) { stub_everything 'http' }
  let(:httpok) { Net::HTTPOK.new('1.1', 200, '') }
  before :each do
    File.stubs(:exist?).with('/dev/null/http_summary.yaml').returns(true)
  end

  context 'when called with a changed report' do
    let(:processor) do
      processor = Puppet::Transaction::Report.new('apply')
      processor.extend(http_summary)
    end

    before :each do
      processor.initialize_from_hash(changed.to_data_hash)
    end

    describe 'when setting up the connection with https' do
      before do
        YAML.stubs(:load_file).with('/dev/null/http_summary.yaml').returns(
          'url'    => 'https://localhost:8888',
          'status' => ['changed'] 
        )
        http.expects(:post).returns(httpok)
      end

      it 'should send report via https' do
        Puppet::Network::HttpPool.expects(:http_instance).with(
          'localhost', 8888, true
        ).returns http

        processor.process
      end
    end

    describe 'when setting up the connection with http' do
     before do
        YAML.stubs(:load_file).with('/dev/null/http_summary.yaml').returns(
          'url'    => 'http://localhost:8888',
          'status' => ['changed'] 
        )
        http.expects(:post).returns(httpok)
      end

      it 'should send report via http' do
        Puppet::Network::HttpPool.expects(:http_instance).with(
          'localhost', 8888, false
        ).returns http

        processor.process
      end
    end

    describe 'when parsing reports' do
      it 'should return the right json object' do
        response = {
          'host'             => 'laura.puppetlabs.vm',
          'time'             => '2017-11-09 21:09:17 +0000',
          'status'           => 'changed',
          'totalResources'   => 8,
          'changedResources' => 1,
          'failedResources'  => 0
        }

        expect(processor.parse_report(processor)).to eq(response.to_json)
      end
    end
  end

  context 'when called with an unchanged report' do
    let(:processor) do
      processor = Puppet::Transaction::Report.new('apply')
      processor.extend(http_summary)
    end

    before :each do
      processor.initialize_from_hash(unchanged.to_data_hash)
    end

    it 'should not parse the report' do
      processor.expects(:send).never
    end

    it 'should not port to url' do
      processor.expects(:parse_report).never
    end
  end
end
