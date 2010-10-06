#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require 'bundler'
Bundler.require(:default)

require File.join( File.dirname( __FILE__ ),'lib', 'postpolicy' )

# this is to require the custom callbacks 
Dir[File.join( File.dirname( __FILE__ ),'callbacks',"*.rb")].each {|file| require file } 

DEFAULT_CONFIG = File.join( File.dirname( __FILE__ ), 'config.yml')

DEFAULT_OPTIONS = { 
  :verbose => false,
  :config_path => DEFAULT_CONFIG
}

begin
  options = DEFAULT_OPTIONS
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"

    opts.on("-v", "--verbose", "Verbose logging") do |v|
      options[:verbose] = v
    end

    opts.on("-c", "--config", "Path to configuration file") do |c|
      options[:config_path] = c
    end
  end.parse!

  Logger.info "Starting PostPolicy #{PostPolicy::VERSION::STRING}"
  policies = YAML.load_file(options[:config_path])
  DEFAULT_ACTION = policies.delete("DEFAULT_ACTION") || "DUNNO" 
  
  app = PostPolicy::Protocol.new
  app.policies = policies
  app.start!
rescue
  Logger.error( $!.message )
  raise $!
end
