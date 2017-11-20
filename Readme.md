## http_summary

Puppet report processor inspired on [Puppet http](https://puppet.com/docs/puppet/5.3/report.html#http),
but instead of sending the full report, it sends an aggregation of resources data in JSON format if
there are changes or failures

```
{"host":"10-32-175-155.rfc1918.puppetlabs.net","time":"2017-11-07 20:00:13 UTC","status":"changed","totalResources":1117,"changedResources":2,"failedResources":0}
```

### Setup

- Install the module
- In the master, enable the http_summary report in puppet.conf:

```
[master]
reports = puppetdb,http_summary
```

- Place a file in $confdir/http_summary.yaml containing url to connect to and
a list of report status to notify to:

```
root@puppet::master /root> cat /etc/puppetlabs/puppet/http_summary.yaml
---
url: 'http://localhost:8888'
status:
  - 'changed'
  - 'failed'
```

- Run puppet agent in the master
- Reload/restart pe-puppetserver

```
service pe-puppetserver reload
```

- Check output in puppetserver.log:

```
2017-11-07 20:05:30,019 INFO  [qtp433110109-11490] [puppetserver] Puppet Compiled static catalog for 10-32-174-86.rfc1918.puppetlabs.net in environment production in 0.98 seconds
2017-11-07 20:05:30,019 INFO  [qtp433110109-11490] [puppetserver] Puppet Caching catalog for 10-32-174-86.rfc1918.puppetlabs.net
2017-11-07 20:05:30,129 INFO  [qtp433110109-11490] [puppetserver] Puppet 'replace_catalog' command for 10-32-174-86.rfc1918.puppetlabs.net submitted to PuppetDB with UUID 48408d23-802c-4397-b6e1-eac2d5f2d70d
2017-11-07 20:05:32,817 INFO  [qtp433110109-11455] [puppetserver] Puppet 'store_report' command for 10-32-174-86.rfc1918.puppetlabs.net submitted to PuppetDB with UUID 04eefeb0-ce1c-4f58-b150-8a2122885589
2017-11-07 20:05:32,820 INFO  [qtp433110109-11455] [puppetserver] Puppet Report successfully sent to http://localhost:8888/
```

- All set!
