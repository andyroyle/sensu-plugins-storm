#!/usr/bin/env ruby
#
# Storm Topology Metrics
# ===
#
# Copyright 2016 Andy Royle <ajroyle@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# Metrics for storm topologies

require 'sensu-plugin/metric/cli'
require 'rest-client'
require 'openssl'
require 'uri'
require 'json'
require 'base64'

class MetricsStormCapacity < Sensu::Plugin::Metric::CLI::Graphite
  option :host,
         short: '-h',
         long: '--host=VALUE',
         description: 'Cluster host',
         required: true

  option :user,
         short: '-u',
         long: '--username=VALUE',
         description: 'username',
         required: true

  option :pass,
         short: '-p',
         long: '--password=VALUE',
         description: 'password',
         required: true

  option :ssl,
         description: 'use HTTPS (default false)',
         long: '--ssl'

  option :timeout,
         short: '-t',
         long: '--timeout=VALUE',
         description: 'Timeout in seconds',
         proc: proc { |l| l.to_f },
         default: 5

  option :scheme,
         short: '-s',
         long: '--scheme=VALUE',
         description: 'Metric naming scheme, text to prepend to metric',
         default: "#{Socket.gethostname}.storm"

  def request(path)
    protocol = config[:ssl] ? 'https' : 'http'
    auth = Base64.encode64("#{config[:user]}:#{config[:pass]}")
    RestClient::Request.execute(
      method: :get,
      url: "#{protocol}://#{config[:host]}:#{config[:port]}/#{path}",
      timeout: config[:timeout],
      headers: { 'Authorization' => "Basic #{auth}" }
    )
  end

  def run
    metrics = %w(emitted tasks failed executors processLatency executeLatency transferred capacity acked executed)

    r = request('/stormui/api/v1/topology/summary')

    topologies = JSON.parse(r.to_str)['topologies']
    topologies.each do |topology|
      t = request("/stormui/api/v1/topology/#{topology['id']}")

      bolts = JSON.parse(t.to_str)['bolts']
      bolts.each do |bolt|
        metrics.each { |metric| output "#{config[:scheme]}.#{topology['name']}.#{bolt['boltId']}.#{metric}", bolt[metric] }
      end

      ok
    end
  end
end
