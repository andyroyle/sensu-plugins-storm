#!/usr/bin/env ruby
#
# Storm Capacity Check
# ===
#
# Copyright 2016 Andy Royle <ajroyle@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# Check the capacity of all running bolts (in all topologies) and compare to crit/warn thresholds

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'openssl'
require 'uri'
require 'json'
require 'base64'

class CheckStormTopologies < Sensu::Plugin::Check::CLI
  option :host,
         short: '-h',
         long: '--host=VALUE',
         description: 'Cluster host'

  option :user,
         short: '-u',
         long: '--username=VALUE',
         description: 'username'

  option :pass,
         short: '-p',
         long: '--password=VALUE',
         description: 'password'

  option :ssl,
         description: 'use HTTPS (default false)',
         long: '--ssl'

  option :crit,
         short: '-c',
         long: '--critical=VALUE',
         description: 'Critical threshold'

  option :warn,
         short: '-w',
         long: '--warn=VALUE',
         description: 'Warn threshold'

  option :timeout,
         short: '-t',
         long: '--timeout=VALUE',
         description: 'Timeout in seconds',
         default: 5

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
    critical_usage = config[:crit].to_f
    warn_usage = config[:warn].to_f

    if [config[:host], config[:user], config[:pass]].any?(&:nil?)
      unknown 'Must specify host, user and password'
    end

    r = request('/stormui/api/v1/topology/summary')

    if r.code != 200
      critical "unexpected status code '#{r.code}'"
    end

    topologies = JSON.parse(r.to_str)['topologies']
    topologies.each do |topology|
      t = request("/stormui/api/v1/topology/#{topology['id']}")
      if t.code != 200
        critical "unexpected status code '#{r.code}'"
      end

      bolts = JSON.parse(t.to_str)['bolts']
      bolts.each do |bolt|
        capacity = bolt['capacity'].to_f
        if capacity > critical_usage
          critical "bolt #{bolt['boltId']} has capacity #{bolt['capacity']}"
        elsif capacity > warn_usage
          warn "bolt #{bolt['boltId']} has capacity #{bolt['capacity']}"
        end
      end

      ok 'all capacities ok'
    end

  rescue Errno::ECONNREFUSED => e
    critical 'Storm is not responding' + e.message
  rescue RestClient::RequestTimeout
    critical 'Storm Connection timed out'
  rescue StandardError => e
    unknown 'An exception occurred:' + e.message
  end
end
