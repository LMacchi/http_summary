require 'puppet'
require 'puppet/network/http_pool'
require 'uri'
require 'json'

Puppet::Reports.register_report(:http_summary) do
  desc "Process aggregated stats from a Puppet report and post them to HTTP"

  def process
    url  = URI.parse(Puppet[:reporturl])
    headers = { "Content-Type" => "application/json" }

    options = { :metric_id => [:puppet, :report, :http] }
    if url.user && url.password
      options[:basic_auth] = {
        :user => url.user,
        :password => url.password
      }
    end
    use_ssl = url.scheme == 'https'

    processed_report = JSON.parse(parse_report(self))

    Puppet.notice "Attempting to send report to #{url.to_s}"
    conn = Puppet::Network::HttpPool.http_instance(url.host, url.port, use_ssl)
    response = conn.post(url.path, processed_report, headers, options)
    unless response.kind_of?(Net::HTTPSuccess)
      Puppet.err "Unable to submit report to #{url.to_s} - error #{response.code}: #{response.msg}"
    end
  end


# Finished puppet run on 10-32-175-155.rfc1918.puppetlabs.net - Success!
# Resource events: 0 failed 2 changed 1,115 unchanged 0 skipped 0 noop
# Report: https://10-32-175-155.rfc1918.puppetlabs.net/#/run/jobs/5/nodes/10-32-175-155.rfc1918.puppetlabs.net/report
  def parse_report(report)
    metrics = {}
    body = {}
    report.status != nil ? status = report.status : status = 'undefined'

    resources = report.metrics['resources'].values
    resources.each do |resource|
      metrics[resource[0]] = resource[2]
    end

    body['host'] = report.host
    body['time'] = report.time
    body['status'] = status
    body['totalResources'] = metrics['total']
    body['changedResources'] = metrics['changed']
    body['failedResources'] = metrics['failed']

    return body.to_json
  end
end
