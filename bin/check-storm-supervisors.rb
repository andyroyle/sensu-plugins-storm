#!/usr/bin/env ruby
#
# Storm Supervisors Check
# ===
#
# Copyright 2016 Andy Royle <ajroyle@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# Check the number of supervisors for a given cluster and compare to warn/minimum thresholds

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'openssl'
require 'uri'
require 'json'
require 'base64'

class CheckStormSupervisors < Sensu::Plugin::Check::CLI
  option :host,
         short: '-h',
         long: '--host=VALUE',
         description: 'Cluster host',
         default: 'localhost'

  option :port,
         short: '-o',
         long: '--port=VALUE',
         description: 'Port (default 8080)',
         default: 8080

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
         description: 'Minimum (critical) supervisors',
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
    if config[:user]
      auth = Base64.encode64("#{config[:user]}:#{config[:pass]}")
      RestClient::Request.execute(
        method: :get,
        url: "#{protocol}://#{config[:host]}:#{config[:port]}#{path}",
        timeout: config[:timeout],
        headers: { 'Authorization' => "Basic #{auth}" }
      )
    else
      RestClient::Request.execute(
        method: :get,
        url: "#{protocol}://#{config[:host]}:#{config[:port]}#{path}",
        timeout: config[:timeout]
      )
    end
  end

  def run
    r = request('/api/v1/cluster/summary')

    if r.code != 200
      critical "unexpected status code '#{r.code}'"
    end

    cluster = JSON.parse(r.to_str)
    supervisors = cluster['supervisors'].to_i

    if supervisors < config[:crit]
      critical "supervisor count #{supervisors} is below allowed minimum of #{config[:crit]}"
    elsif supervisors < config[:warn]
      warning "supervisor count #{supervisors} is below warn threshold of #{config[:warn]}"
    end

    ok 'supervisor count OK'

  rescue Errno::ECONNREFUSED => e
    critical 'Storm is not responding' + e.message
  rescue RestClient::RequestTimeout
    critical 'Storm Connection timed out'
  rescue StandardError => e
    unknown 'An exception occurred:' + e.message
  end
end
