require 'rubygems'
require 'eventmachine'

$:.unshift File.dirname( __FILE__ )

require 'postpolicy/access_manager'
require 'postpolicy/config'
require 'postpolicy/logger'
require 'postpolicy/extensions'
require 'postpolicy/server'
require 'postpolicy/version'

VERBOSE = false unless defined?( VERBOSE )
