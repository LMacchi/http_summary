require 'spec_helper'
require 'puppet/reports'

http_summary = Puppet::Reports.report(:http_summary)

describe http_summary do
  let(:processor) do
    processor = Puppet::Transaction::Report.new('apply')
    processor.extend(http_summary)
  end

  describe "when setting up the connection" do
    let(:http) { stub_everything "http" }
    let(:httpok) { Net::HTTPOK.new('1.1', 200, '') }

    before do
      File.stubs(:exist?).with('/dev/null/http_summary.yaml').returns(true)
      YAML.stubs(:load_file).with('/dev/null/http_summary.yaml').returns(
        {
          'url' => 'https://localhost:8888',
        }
      )
      http.expects(:post).returns(httpok)
    end

    it "configures the connection for ssl when using https" do
      Puppet::Network::HttpPool.expects(:http_instance).with(
        'localhost', 8888, true
      ).returns http

      processor.add_metric(:resources, {"total" => 178, "failed" => 0, "changed" => 0})
    
      processor.process
    end
  end
end
