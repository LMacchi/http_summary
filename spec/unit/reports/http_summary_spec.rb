require 'spec_helper'
require 'puppet/reports'

http_summary = Puppet::Reports.report(:http_summary)

describe http_summary do
  let(:processor) do
    processor = Puppet::Transaction::Report.new('apply')
    processor.extend(http_summary)
  end
  
  before :each do
    http.expects(:post).returns(httpok)
    File.stubs(:exist?).with('/dev/null/http_summary.yaml').returns(true)
  end

  let(:http) { stub_everything "http" }
  let(:httpok) { Net::HTTPOK.new('1.1', 200, '') }

  describe "when setting up the connection with https" do

    before do
      YAML.stubs(:load_file).with('/dev/null/http_summary.yaml').returns(
        {
          'url' => 'https://localhost:8888',
        }
      )
    end

    it "should send report via https" do
      Puppet::Network::HttpPool.expects(:http_instance).with(
        'localhost', 8888, true
      ).returns http

      processor.add_metric(:resources, {"total" => 178, "failed" => 0, "changed" => 0})
    
      processor.process
    end

    describe "when setting up the connection with http" do

      before do
        YAML.stubs(:load_file).with('/dev/null/http_summary.yaml').returns(
          {
            'url' => 'http://localhost:8888',
          }
        )
      end

      it "should send report via http" do
        Puppet::Network::HttpPool.expects(:http_instance).with(
          'localhost', 8888, false
        ).returns http

        processor.add_metric(:resources, {"total" => 178, "failed" => 0, "changed" => 0})
      
        processor.process
      end
    end
  end
end
