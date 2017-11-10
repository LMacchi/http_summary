require 'spec_helper'
require 'puppet/reports'
require 'yaml'

http_summary = Puppet::Reports.report(:http_summary)

describe http_summary do
  context 'with an unchanged report' do
    let(:unchanged) do
      f = my_fixture 'report_unchanged.yaml'
      YAML.load_file(f)
    end
    let(:u_processor) do
      u_processor = Puppet::Transaction::Report.new('apply')
      u_processor.extend(http_summary) 
    end

    before do
      u_processor.initialize_from_hash(unchanged.to_data_hash)
    end

    it 'should not parse report' do
        u_processor.process
        u_processor.expects(:parse_report).never
    end

    it 'should not post to url' do
      u_processor.process
      u_processor.expects(:send).never
    end
  end

  context 'with an changed report' do
    let(:changed) do
      f = my_fixture 'report_changed.yaml'
      YAML.load_file(f)
    end
    let(:c_processor) do
      c_processor = Puppet::Transaction::Report.new('apply')
      c_processor.extend(http_summary) 
    end

    before do
      File.stubs(:exist?).with('/dev/null/http_summary.yaml').returns(true)
      YAML.stubs(:load_file).with('/dev/null/http_summary.yaml').returns(
        'url' => 'https://localhost:8888'
      )
      c_processor.initialize_from_hash(changed.to_data_hash)
    end

    it 'should parse report' do
      c_processor.process
      c_processor.expects(:parse_report).with(c_processor)
    end
  end
end
