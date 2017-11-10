require 'puppet'
require 'puppet/network/http_pool'
require 'uri'
require 'json'

Puppet::Reports.register_report(:http_summary) do
  desc 'Process aggregated stats from a Puppet report and post them to HTTP'

  def read_config
    configfile = File.join([File.dirname(Puppet.settings[:config]), 'http_summary.yaml'])
    raise(Puppet::ParseError, "http_summary report config file #{configfile} not readable") unless File.exist?(configfile)
    begin
      config = YAML.load_file(configfile)
    rescue Psych::SyntaxError
      raise Puppet::ParseError, "http_summary file #{configfile} is not valid YAML!"
    end
    config
  end

  def process
    status = !self.status.nil? ? self.status : 'undefined'

    return unless %w[failed changed].include? status

    send(parse_report(self))
  end

  def calculate_defaults(url)
    headers = { 'Content-Type' => 'application/json' }
    options = { :metric_id => [:puppet, :report, :http] }
    if url.user && url.password
      options[:basic_auth] = {
        user: url.user,
        password: url.password
      }
    end
    use_ssl = url.scheme == 'https'

    [headers, options, use_ssl]
  end

  def send(message)
    config = read_config
    uri = config['url']

    raise Puppet::ParseError, 'Could not find valid url in configuration file' unless !uri.nil?

    begin
      url = URI.parse(uri)
    rescue URI::InvalidURIError, URI::BadURIError
      raise Puppet::ParseError, 'Could not find valid url in configuration file'
    end

    headers, options, use_ssl = calculate_defaults(url)

    conn = Puppet::Network::HttpPool.http_instance(url.host, url.port, use_ssl)
    response = conn.post(url.path, message, headers, options)

    if !response.is_a?(Net::HTTPSuccess)
      Puppet.err "Unable to submit report to #{url} - error #{response.code}: #{response.msg}"
    else
      Puppet.notice "Report successfully sent to #{url}"
    end
  end

  def parse_report(report)
    body = {}

    body['host'] = report.host
    body['time'] = report.time
    body['status'] = report.status
    body['totalResources'] = report.metrics['resources']['total']
    body['changedResources'] = report.metrics['resources']['changed']
    body['failedResources'] = report.metrics['resources']['failed']

    body.to_json
  end
end
