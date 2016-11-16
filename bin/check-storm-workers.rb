#!/usr/bin/env ruby
#
# Storm Workers Check
# ===
#
# Copyright 2016 Andy Royle <ajroyle@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# Check the number of workers (supervisors) for a given cluster and compare to warn/minimum thresholds

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'openssl'
require 'uri'
require 'json'
require 'base64'

class CheckStormCapacity < Sensu::Plugin::Check::CLI
  option :host,
         short: '-h',
         long: '--host=VALUE',
         description: 'Cluster host',
         default: 'localhost'

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

  option :crit,
         short: '-m',
         long: '--minimum=VALUE',
         description: 'Minimum (critical) workers',
         required: true,
         proc: proc { |l| l.to_i }

  option :warn,
         short: '-w',
         long: '--warn=VALUE',
         description: 'Warn threshold',
         required: true,
         proc: proc { |l| l.to_i }

  option :timeout,
         short: '-t',
         long: '--timeout=VALUE',
         description: 'Timeout in seconds',
         proc: proc { |l| l.to_i },
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
    r = request('/api/v1/cluster/summary')

    if r.code != 200
      critical "unexpected status code '#{r.code}'"
    end

    cluster = JSON.parse(r.to_str)
    workers = cluster['supervisors'].to_i

    if workers < config[:crit]
      critical "worker count #{workers} is below allowed minimum of #{config[:crit]}"
    elsif workers < config[:warn]
      warning "worker count #{workers} is below warn threshold of #{config[:warn]}"
    end

    ok 'worker count OK'

  rescue Errno::ECONNREFUSED => e
    critical 'Storm is not responding' + e.message
  rescue RestClient::RequestTimeout
    critical 'Storm Connection timed out'
  rescue StandardError => e
    unknown 'An exception occurred:' + e.message
  end
end
