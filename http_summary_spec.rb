require 'spec_helper'
require 'puppet/reports'

http_summary = Puppet::Reports.report(:http_summary)

describe http_summary do
  let(:http) { stub_everything 'http' }
  let(:httpok) { Net::HTTPOK.new('1.1', 200, '') }
  let(:host) { 'laura.puppetlabs.vm' }
  let(:time) { '2017-11-06T21:44:40.258493862Z' }
  let(:resources) { { 'total' => 178, 'failed' => 0, 'changed' => 1 } }

  before :each do
    File.stubs(:exist?).with('/dev/null/http_summary.yaml').returns(true)
  end

  describe 'when providing url with https in the conf file' do
    let(:processor) { Puppet::Transaction::Report.new('apply').extend(http_summary) }

    before do
      YAML.stubs(:load_file).with('/dev/null/http_summary.yaml').returns(
        'url' => 'https://localhost:8888'
      )
      http.expects(:post).returns(httpok)
    end

    it 'should send report via https' do
      Puppet::Network::HttpPool.expects(:http_instance).with(
        'localhost', 8888, true
      ).returns http

      processor.add_metric(:resources, resources)

      processor.process
    end
  end

  describe 'when providing url with http in the conf file' do
   let(:processor) { Puppet::Transaction::Report.new('apply').extend(http_summary) }

   before do
      YAML.stubs(:load_file).with('/dev/null/http_summary.yaml').returns(
        'url' => 'http://localhost:8888'
      )
      http.expects(:post).returns(httpok)
      processor.add_metric(:resources, resources)
    end

    it 'should send report via http' do
      Puppet::Network::HttpPool.expects(:http_instance).with(
        'localhost', 8888, false
      ).returns http

      processor.process
    end
  end

  describe 'when report has no changes' do
    let(:processor) { Puppet::Transaction::Report.new('apply').extend(http_summary) }
    before do
      processor.add_metric(:resources, resources)
      processor.finalize_report
    end

    it 'should not post to url' do
      processor.expects(:send).never
    end
  end

  describe 'when parsing reports' do
    let(:processor) { Puppet::Transaction::Report.new('apply').extend(http_summary) }
    before do
      processor.finalize_report
      processor.add_metric(:resources, resources)
    end

   it 'should return the right json object' do
      processor.expects(:host).returns(host)
      processor.expects(:time).returns(time)
      processor.expects(:status).returns('changed')

      response = {
        'host'             => host,
        'time'             => time,
        'status'           => 'changed',
        'totalResources'   => 178,
        'changedResources' => 1,
        'failedResources'  => 0
      }

      expect(processor.parse_report(processor)).to eq(response.to_json)
    end
  end
end
