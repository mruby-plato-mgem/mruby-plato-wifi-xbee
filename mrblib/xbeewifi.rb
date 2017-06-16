#
# PlatoDevice::XBeeWifi class
#
module PlatoDevice
  class XBeeWiFi < Plato::WiFi
    include Plato
    CR = "\r"
    TMO_RESPONSE = 2000
    @@wifi = nil
    @@resolv = {}

    def initialize
      super
      @wifi = Plato::Serial.open(9600, 8, 1, 1, :none)
    end

    def self.open
      @@wifi = self.new unless @@wifi
      @@wifi
    end

    def config(sw=nil)
      if sw
        bt = Plato::ButtonSwitch.new(sw)
        tmo = Machine.millis + 1000
        while tmo > Machine.millis
          if bt.on?
            XBeeWiFiConfig.new(self).menu
            break
          end
          Machine.delay(1)
        end
      end
      self
    end

    def atcmd(cmds, tmo=2000)
      cmds = [cmds] unless cmds.instance_of?(Array)
      rsp = []
      begin
        enter_at_mode
        cmds.each {|c|
          rsp << cmd(c, tmo)
        }
        cmd "ATCN"
        # rsp = rsp[0] if rsp.size == 1
      rescue
      end
      return rsp.size <= 1 ? rsp[0] : rsp
    end

    def cmd(c, tmo=2000)
      self.write "#{c}#{CR}"
      wait_cr tmo
    end

    def _write(c); @wifi._write(c); end
    def _read; @wifi._read; end
    def available; @wifi.available; end
    def flush; @wifi.flush; end

    def close
      if @wifi
        atcmd ["ATDL0.0.0.0", "ATDE0"]
        # @wifi.close   # disable enzi debug message
        # @wifi = nil
      end
    end

    # Wait for CR reception, copy from zigbee
    def wait_cr(tmo=nil)
      tmo += Machine.millis if tmo
      s = ""
      while true
        c = @wifi.getc
        return s if c == CR
        if c
          s << c
        else
          raise "XBee-wifi response timeout #{s}" if tmo && tmo <= Machine.millis
          Machine.delay(1)
        end
      end
    end

    # Enter AT command mode
    def enter_at_mode
      while gets.size > 0; end  # discard remain data
      Machine.delay(1000) # wait 1 second
      10.times do
        begin
          self.write '+++'
          Machine.delay(1000) # wait 1 second
          rsp = wait_cr(TMO_RESPONSE)
          return rsp
        rescue => e
        end
      end
      raise "Cannot enter AT mode"
    end

    # get XBee WiFi status (association indicator)
    def status
      sts = atcmd "ATAI"
      sts.to_i(16)
    end

    # wait for connection to AP
    def wait_connect(trycnt=10)
      trycnt.times do
        case sts = status
          when 0x00;  return
          when 0x23;  raise "SSID not configured"
          when 0x24;  raise "Encryption key invalid"
          when 0x27;  raise "SSID was found, but join failed"
          # else; Object.puts "status = 0x#{sts.to_s(16)}"
        end
      end
      raise "Cannot connect to target"
    end

    # connect to destination
    def connect(dest, port=80)
      @dest = dest
      @port = port
      atcmd ["ATDL#{@dest}", "ATDE#{@port.to_s(16)}"]
      wait_connect
    end

    # get ip address
    def ip_address
      atcmd "ATMY"
    end

    # get mac address
    def mac_address
      rsp = atcmd ["ATSH", "ATSL"]
      return ('0' * 3 + rsp[0])[-4, 4] + ('0' * 7 + rsp[1])[-8, 8]
    end

    # ping command
    def ping(ip)
      atcmd "ATPG#{ip}", 5000
    end

    # DNS Lookup
    def dns_lookup(fqdn)
      rsp = @@resolv[fqdn]
      # Object.puts "#{fqdn}: #{rsp}" if rsp
      return rsp if rsp
      addr = atcmd "ATLA#{fqdn}", 15000
      if addr == 'ERROR' || !IPSocket.valid_address?(addr)
        raise "#{fqdn} not provided"
      end
      # Object.puts "#{fqdn}: #{addr}"
      @@resolv[fqdn] = addr
    end

    # reset network
    def reset
      atcmd "ATNR", 3000
    end

    # scan for access points
    def scan_ap
      enter_at_mode
      self.write "ATAS#{CR}"
      ap = []
      loop {
        sc = wait_cr 3000 # scan type
        break if !sc || sc.size == 0 || sc == 'ERROR'
        ch = wait_cr      # channel number
        st = wait_cr      # security type ('00':open, '01':WPA, '02':WPA2, '03':WEP)
        lm = wait_cr      # Link margin
        id = wait_cr      # SSID
        sec_type = case st
        when '00';  :none
        when '01';  :wpa
        when '02';  :wpa2
        when '03';  :wep
        else;       nil
        end
        ap << [id, sec_type] # ssid, sec_type
      }
      cmd "ATCN"
      return ap
    end

    # set resolver
    def self.setaddress(fqdn, addr)
      @@resolv[fqdn] = addr
    end
  end
end
