# undef TCPSocket (for enzi)
Object.class_eval do
  remove_const :TCPSocket if const_defined? :TCPSocket
end

class BasicSocket
  include Plato::Serial

  def recv(maxlen, flag=0); read(maxlen); end
  def send(mesg, flag=0); write(mesg); end
end

class IPSocket < BasicSocket
  def self.getaddress(fqdn)
    return fqdn if valid_address?(fqdn)
    wifi = PlatoDevice::XBeeWiFi.open
    wifi.dns_lookup(fqdn)
  end

  def self.valid_address?(addr)
    @@regex = Object.const_defined?(:Regexp)
    ary = addr.split '.'
    return false if ary.size != 4
    ary.each {|s|
      # Numeric check (without Integer(s) for mruby-1.0.0)
      i = s.to_i
      return false unless i.between?(0, 255)
      if i == 0
        return false if @@regex && s =~ /\D/
        s.each_char {|c|
          return false unless c.between?('0', '9')  # without Regexp
        }
      end
    }
    true
  rescue => e
    false
  end

end

class TCPSocket < IPSocket
  TMO_READ = 5000

  def initialize(host, serv)
    # Serial#read setting
    @datatype = :as_string
    @timeout  = TMO_READ
    # initialize XBeeWiFi
    @dev = PlatoDevice::XBeeWiFi.new
    ip = IPSocket.getaddress(host)
    res = @dev.connect(ip, serv)
    self
  end

  def self.open(host, serv)
    self.new(host, serv)
  end

  def _read
    c = @dev._read
    # Object.print c.chr if c >= 0
    c
  end

  def _write(c)
    @dev._write(c)
    # Object.print c.chr
  end

  def available; @dev.available; end
  def flush; @dev.flush; end
  def close; @dev.close; end

end
