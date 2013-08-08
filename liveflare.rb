#!/usr/bin/env ruby
require 'dante'
require_relative 'liveflare_lib'

# Set default port to 8080
runner = Dante::Runner.new('liveflare')
# Sets the description in 'help'
runner.description = "For informations about CloudFlare's API, visit: http://www.cloudflare.com/docs/host-api.html"

# Set custom options
runner.with_options do |opts|
  add_liveflare_options(opts)
end

# Parse command-line options and execute the process
runner.execute do |opts|
  compute_liveflare_options
  check_liveflare_options(opts)
  start
end