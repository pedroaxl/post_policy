require 'bundler'
require 'redis'
require 'callbacks/mailee.rb'

describe Mailee do
  before(:all) do
    @args1 = {
      :request=>"smtpd_access_policy", 
      :protocol_state=>"RCPT", 
      :protocol_name=>"SMTP", 
      :helo_name=>"some.domain.tld", 
      :queue_id=>"8045F2AB23", 
      :sender=>"foo@bar.tld", 
      :recipient=>"pedro@softa.com.br", 
      :recipient_count=>"0", 
      :client_address=>"1.2.3.4", 
      :client_name=>"another.domain.tld", 
      :reverse_client_name=>"another.domain.tld", 
      :instance=>"l0", 
      :sasl_method=>"plain", 
      :sasl_username=>"you", 
      :sasl_sender=>nil, 
      :size=>"12345", 
      :ccert_subject=>"solaris9.porcupine.org", 
      :ccert_issuer=>"Wietse+20Venema", 
      :ccert_fingerprint=>"C2:9D:F4:87:71:73:73:D9:18:E7:C2:F3:C1:DA:6E:04", 
      :encryption_protocol=>"TLSv1/SSLv3", 
      :encryption_cipher=>"DHE-RSA-AES256-SHA", 
      :encryption_keysize=>"256", 
      :etrn_domain=>nil
      }
      r = Redis.new
      @redis_mx = Redis::Namespace.new("#{@args1[:instance]}_mx", :redis => r)
      @redis_threshold = Redis::Namespace.new("threshold", :redis => r)
      @redis_domains = Redis::Namespace.new("#{@args1[:instance]}_domains", :redis => r)
      @redis_hold = Redis::Namespace.new("#{@args1[:instance]}_hold", :redis => r)
      
  end
  
  it "should resolv dns MX records" do
    m = Mailee.new @args1
    m.mx.include?("ASPMX.L.GOOGLE.COM").should == true
    m.mx.include?("ALT1.ASPMX.L.GOOGLE.COM").should == true
    m.mx.include?("ALT2.ASPMX.L.GOOGLE.COM").should == true
    m.mx.include?("ASPMX2.GOOGLEMAIL.COM").should == true
    m.mx.include?("ASPMX3.GOOGLEMAIL.COM").should == true
  end
  
  it "should return false if theres nothing holding that domain" do
    @redis_mx.del 'ASPMX.L.GOOGLE.COM'
    m = Mailee.new @args1
    m.greylisted?.should_not
  end
  
  it "should not return false if theres something holding that domain" do
    @redis_mx.set 'ASPMX.L.GOOGLE.COM', true
    m = Mailee.new @args1
    m.greylisted?.should == 'ASPMX.L.GOOGLE.COM'
    @redis_mx.del 'ASPMX.L.GOOGLE.COM'
    m.greylisted?.should == nil
    
    @redis_mx.set 'ASPMX3.GOOGLEMAIL.COM', true
    m = Mailee.new @args1
    m.greylisted?.should == 'ASPMX3.GOOGLEMAIL.COM'
    @redis_mx.del 'ASPMX3.GOOGLEMAIL.COM'
    m.greylisted?.should == nil
  end
  
  it "should return the threshold of the domain" do
    m = Mailee.new @args1
    m.threshold_of.should == 0
    @redis_threshold.set "softa.com.br", 60
    m.threshold_of.should == 60
    @redis_threshold.del "softa.com.br"
  end
  
  it "should return false and create the record if the domain does not exceeded that threshold" do
    @redis_domains.del("softa.com.br")
    m = Mailee.new @args1
    m.threshold_exceed?.should_not
    Marshal.load(@redis_domains.get("softa.com.br")).empty?.should == false
    @redis_domains.del("softa.com.br")
    @redis_threshold.set "softa.com.br", 3
    @redis_domains.set "softa.com.br", Marshal.dump([Time.now - 240, Time.now - 120])
    Marshal.load(@redis_domains.get("softa.com.br")).size.should == 2
    m.threshold_exceed?.should == false
    Marshal.load(@redis_domains.get("softa.com.br")).size.should == 3
    m.threshold_exceed?.should == true
    Marshal.load(@redis_domains.get("softa.com.br")).size.should == 3
    @redis_threshold.del "softa.com.br"
  end
  
   it "should schedule a message to greylisted domain" do
    m = Mailee.new @args1
    @redis_hold.del "softa.com.br"
    m.schedule_delivery 10
    hash = {:queue_id => '8045F2AB23', :recipient => 'pedro@softa.com.br'}
    Marshal.load(@redis_hold.get("softa.com.br")).should == [hash]
    hash_new = {:queue_id => '8045F2CD23', :recipient => 'joao@softa.com.br'}
    @redis_hold.set "softa.com.br", Marshal.dump([hash_new])
    m.schedule_delivery 1
    array_new = Marshal.load(@redis_hold.get("softa.com.br"))
    array_new.should == [hash_new,hash]
  end
  
  it "should reevaluate the messages on hold" do
    
  end
  
end

