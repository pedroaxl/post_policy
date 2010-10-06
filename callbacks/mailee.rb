class Mailee
  
  require 'redis'
  require 'redis/namespace'
  require 'resolv'
  
  THRESHOLD_EXPIRE = 3600 # seconds
    
  attr_reader :args, :redis, :domain, :mx
    
  def initialize args
    return false unless args[:recipient] and args[:instance]
    @args = args
    r = Redis.new
    @redis_mx = Redis::Namespace.new("#{args[:instance]}_mx", :redis => r)
    @redis_domains = Redis::Namespace.new("#{args[:instance]}_domains", :redis => r)
    @redis_threshold = Redis::Namespace.new("threshold", :redis => r)

    @domain = args[:recipient].split('@').last
    @mx = resolv
  end
  
  def hold?
    return false if mx.empty?
    return true if greylisted?
    return true if threshold_exceed?
    false
  end
    
  def resolv
    mx = []
    Resolv::DNS.open do |dns|
       r = dns.getresources(@domain, Resolv::DNS::Resource::IN::MX)
       r.each {|m| mx << m.exchange.to_s}
    end
    mx
  end
  
  def greylisted?
    @mx.find{|m| @redis_mx.get(m)}
  end
  
  def threshold_exceed?
    r = @redis_domains.get @domain
    messages_sent = []
    if r
      messages_sent = Marshal.load(r).find_all{|e| e >= Time.now - THRESHOLD_EXPIRE }
      return true if threshold_of != 0 and messages_sent.size >= threshold_of
    end
    messages_sent << Time.now
    @redis_domains.setex @domain, THRESHOLD_EXPIRE, Marshal.dump(messages_sent)
    false  
  end
  
  def threshold_of
    @redis_threshold.get(@domain).to_i
  end

end