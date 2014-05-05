#!/usr/bin/env ruby
require 'dante'
require_relative 'lib/liveflare'

class OptionParser
  def remove_switch(short_name, long_name)
    @stack[2].long.reject! { |k| k == long_name }
    @stack[2].short.reject! { |k| k == short_name }
  end
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

# Set custom options
runner.with_options do |opts|
  opts.remove_switch("port", "p")
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
