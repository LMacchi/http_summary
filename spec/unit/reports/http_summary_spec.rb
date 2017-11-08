require 'spec_helper'
require 'puppet/reports'

http_summary = Puppet::Reports.report(:http_summary)

describe http_summary do
  let(:processor) do
    processor = Puppet::Transaction::Report.new('apply')
    processor.extend(http_summary)
  end

  let(:http) { stub_everything "http" }
  let(:httpok) { Net::HTTPOK.new('1.1', 200, '') }
  
  before :each do
    File.stubs(:exist?).with('/dev/null/http_summary.yaml').returns(true)
  end

  describe "when setting up the connection with https" do

    before do
      YAML.stubs(:load_file).with('/dev/null/http_summary.yaml').returns(
        {
          'url' => 'https://localhost:8888',
        }
      )
      http.expects(:post).returns(httpok)
    end


    it "should send report via https" do
      Puppet::Network::HttpPool.expects(:http_instance).with(
        'localhost', 8888, true
      ).returns http

      processor.add_metric(:resources, {"total" => 178, "failed" => 0, "changed" => 1})
    
      processor.process
    end
  end

  describe "when setting up the connection with http" do

    before do
      YAML.stubs(:load_file).with('/dev/null/http_summary.yaml').returns(
        {
          'url' => 'http://localhost:8888',
        }
      )
      http.expects(:post).returns(httpok)
    end

    it "should send report via http" do
      Puppet::Network::HttpPool.expects(:http_instance).with(
        'localhost', 8888, false
      ).returns http

      processor.add_metric(:resources, {"total" => 178, "failed" => 0, "changed" => 0})
    
      processor.process
    end
  end

  describe "when parsing reports" do

    it "should return the right json object" do
      processor.expects(:host).returns('laura.puppetlabs.vm')
      processor.expects(:time).returns('2017-11-06T21:44:40.258493862Z')
      processor.expects(:status).returns('changed')
      processor.add_metric(:resources, {"total" => 178, "failed" => 0, "changed" => 1})

      response = {"host":"laura.puppetlabs.vm","time":"2017-11-06T21:44:40.258493862Z","status":"changed","totalResources":178,"changedResources":1,"failedResources":0}

      expect(processor.parse_report(processor)).to eq(response.to_json)
    end
  end

end
