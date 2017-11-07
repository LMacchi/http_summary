require 'puppet'
require 'puppet/network/http_pool'
require 'uri'
require 'json'

Puppet::Reports.register_report(:http_summary) do
  desc "Process aggregated stats from a Puppet report and post them to HTTP"

  def read_config
    configfile = File.join([File.dirname(Puppet.settings[:config]), "http_summary.yaml"])
    raise(Puppet::ParseError, "http_summary report config file #{configfile} not readable") unless File.exist?(configfile)
    begin
      config = YAML.load_file(configfile)
    rescue TypeError => e
      raise Puppet::ParserError, "http_summary file #{configfile} is not valid YAML!"
    end
    config
  end

  def process
    config = read_config
    url  = URI.parse(config['url'])
    headers = { "Content-Type" => "application/json" }

    options = { :metric_id => [:puppet, :report, :http] }
    if url.user && url.password
      options[:basic_auth] = {
        :user => url.user,
        :password => url.password
      }
    end
    use_ssl = url.scheme == 'https'
    
    self.status != nil ? status = self.status : status = 'undefined'

    if status == 'failed' or status == 'changed'
    
      processed_report = parse_report(self)

      conn = Puppet::Network::HttpPool.http_instance(url.host, url.port, use_ssl)
      response = conn.post(url.path, processed_report, headers, options)

      if ! response.kind_of?(Net::HTTPSuccess)
        Puppet.err "Unable to submit report to #{url.to_s} - error #{response.code}: #{response.msg}"
      else
        Puppet.notice "Report successfully sent to #{url.to_s}"
      end
    end
  end

  def parse_report(report)
    metrics = {}
    body = {}

    resources = report.metrics['resources'].values
    resources.each do |resource|
      metrics[resource[0]] = resource[2]
    end

    body['host'] = report.host
    body['time'] = report.time
    body['status'] = report.status
    body['totalResources'] = metrics['total']
    body['changedResources'] = metrics['changed']
    body['failedResources'] = metrics['failed']

    return body.to_json
  end
end
