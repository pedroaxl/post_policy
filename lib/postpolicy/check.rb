require 'rubygems'
require 'eventmachine'

module PostPolicy

  class Check
  
    include EventMachine::Deferrable
    
    def initialize
      @policies = {}
    end
    
    attr_accessor :policies

    def check(args)
      action = DEFAULT_ACTION
      @policies.each do |name,policy|
        if eval policy["callback"]
          action = policy["match"] 
          break
        end
      end
      yield action if block_given?
      action
    end

  end
end

