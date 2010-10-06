require 'rubygems'

$:.unshift File.dirname( __FILE__ )

require 'postpolicy/check'
require 'postpolicy/extensions'
require 'postpolicy/logger'
require 'postpolicy/protocol'
require 'postpolicy/server'
require 'postpolicy/version'

VERBOSE = false unless defined?( VERBOSE )
