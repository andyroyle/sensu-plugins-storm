## Sensu-Plugins-Storm

[ ![Build Status](https://travis-ci.org/andyroyle/sensu-plugins-storm.svg?branch=master)](https://travis-ci.org/andyroyle/sensu-plugins-storm)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-storm.svg)](http://badge.fury.io/rb/sensu-plugins-storm)
[![Code Climate](https://codeclimate.com/github/andyroyle/sensu-plugins-storm/badges/gpa.svg)](https://codeclimate.com/github/andyroyle/sensu-plugins-storm)
[![Test Coverage](https://codeclimate.com/github/andyroyle/sensu-plugins-storm/badges/coverage.svg)](https://codeclimate.com/github/andyroyle/sensu-plugins-storm)

## Functionality

## Files
 * bin/check-storm-topologies.rb
 * bin/check-storm-capacity.rb

## Usage

**check-storm-topologies** example
```bash
/opt/sensu/embedded/bin$ /opt/sensu/embedded/bin/ruby check-storm-topologies.rb --host=my-storm-cluster.com -s --user=admin --password=password --expect=1
```


**check-storm-capacity** example
```bash
/opt/sensu/embedded/bin$ /opt/sensu/embedded/bin/ruby check-storm-capacity.rb --host=my-storm-cluster.com -s --user=admin --password=password -w 1 -c 1.5
```

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes
The ruby executables are install in path similar to `/opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/sensu-plugins-storm-0.1.0/bin`
