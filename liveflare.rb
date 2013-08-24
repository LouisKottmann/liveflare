#!/usr/bin/env ruby
require 'dante'
require_relative 'lib/liveflare'

class OptionParser
  attr_accessor :stack
end

module Dante
  class Runner
    def log(message)
      lflog(message)
    end
  end
end

runner = Dante::Runner.new('liveflare')

liveflare = LiveFlare.new

def remove_switch(opts, short_name, long_name)
  opts.stack[2].long.reject! { |k| k == long_name }
  opts.stack[2].short.reject! { |k| k == short_name }
end

# Set custom options
runner.with_options do |opts|
  remove_switch(opts, "port", "p")
  liveflare.add_options(opts)
end

# Parse command-line options and execute the process
runner.execute do |opts|
  liveflare.compute_options
  if liveflare.missing_options?
    runner.stop
  else
    liveflare.start
  end
end
