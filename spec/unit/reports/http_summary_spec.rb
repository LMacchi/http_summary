require 'spec_helper'
require 'puppet/reports'
require 'yaml'

http_summary = Puppet::Reports.report(:http_summary)

describe http_summary do
  context 'with an unchanged report' do
    let(:unchanged) do
      f = my_fixture 'report_unchanged.yaml'
      YAML.load File.new(f, 'r')
    end
    let(:processor) do
      processor = Puppet::Transaction::Report.new('apply')
      processor.extend(http_summary) 
    end

    before do
      processor.initialize_from_hash(unchanged.to_data_hash)
    end

    it 'should not parse report' do
        processor.process
        processor.expects(:parse_report).never
    end

    it 'should not post to url' do
      processor.process
      processor.expects(:send).never
    end
  end

  context 'with a changed report and https' do
    let(:changed) do
      f = my_fixture 'report_changed.yaml'
      YAML.load File.new(f, "r")
    end
    let(:processor) do
      processor = Puppet::Transaction::Report.new('apply')
      processor.extend(http_summary) 
    end
    let(:http) { stub_everything "http" }
    let(:httpok) { Net::HTTPOK.new('1.1', 200, '') }

    before do
      File.stubs(:exist?).with(anything).returns(true)
      YAML.stubs(:load_file).with('/dev/null/http_summary.yaml').returns(
        'url' => 'https://localhost:8888'
      )
      processor.initialize_from_hash(changed.to_data_hash)
      http.expects(:post).returns(httpok)
    end

    it "configures the connection for ssl when using https" do
      Puppet::Network::HttpPool.expects(:http_instance).with(
        'localhost', 8888, true
      ).returns http

      processor.process
    end

    it 'should parse report' do
      processor.process
      processor.expects(:parse_report).with(processor)
    end
  end
end
