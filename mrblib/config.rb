# XBee-WiFi configuration tool

class XBeeWiFiConfig
  STATUS = {
    0x00 => 'Successfully joined an AP',
    0x01 => 'WiFi transceiver initialization in progress',
    0x02 => 'WiFi transceiver initialized, but not yet scanning for AP',
    0x13 => 'Disconnecting from AP',
    0x23 => 'SSID not configured',
    0x24 => 'Encryption key invalid',
    0x27 => 'SSID was found, but join failed',
    0x41 => 'Module is joined a network and is waiting for IP configurations to complete',
    0x42 => 'Module is joined, IP is configured, and listening sockets are being set up',
    0xff => 'Module is currently scanning for the configured SSID'
  }

  def initialize(wifi=nil)
    wifi = PlatoDevice::XBeeWiFi.new unless wifi
    @wifi = wifi
  end

  # Show XBee-WiFi configuration
  def show_config
    cfg = {}
    ca = [
      'ATID',   # SSID
      'ATEE',   # Encription Enale
      'ATAI',   # Association Indication
      'ATMA',   # DHCP/Static
      'ATMY',   # IP address
      'ATMK',   # Subnet mask
      'ATGW',   # Default gateway
      'ATNS'    # DNS
    ]
    res = @wifi.atcmd(ca)
    cfg[:ssid]  = res[0] != 'OK' ? res[0] : nil
    cfg[:enc]   = case res[1]
      when '0'; :none
      when '1'; :wpa
      when '2'; :wpa2
      when '3'; :wep
      else;     :none
    end
    cfg[:status]  = res[2].to_i(16)
    cfg[:dhcp]    = (res[3] == '0')
    cfg[:ipaddr]  = res[4]
    cfg[:subnet]  = res[5]
    cfg[:gateway] = res[6]
    cfg[:dns]     = res[7]

    puts <<EOS
<< WiFi status >>
SSID:     #{cfg[:ssid]}
Security: #{cfg[:enc].to_s.upcase}
Status:   0x#{cfg[:status].to_s(16)} (#{STATUS[cfg[:status]]})
<< IPv4 settings >>
DHCP:     #{cfg[:dhcp] ? 'enable' : 'disable'}
IP addr:  #{cfg[:ipaddr]}
Subnet:   #{cfg[:subnet]}
Gateway:  #{cfg[:gateway]}
DNS:      #{cfg[:dns]}
EOS
  end

  # Configure WiFi connection
  def configure_wifi
    config = {}
    puts "Resetting network connection"
    @wifi.reset
    puts "Scanning access points"
    aplist = @wifi.scan_ap
    loop {
      aplist.each_with_index {|ap, i|
        puts "#{i+1}: #{ap[0]} (#{ap[1].to_s.upcase})"
      }
      puts "-" * 16
      puts "S: Specify a SSID"
      puts "R: Rescan access point"
      case apno = input.chomp.strip.downcase
      when 'r'
        aplist = @wifi.scan_ap
      when 's'
        config[:ssid] = input('SSID')
        enc = input('Security type (0:none, 1:WPA, 2:WPA2, 3:WEP)')
        config[:enc] = case enc.to_i
          when 0; :none
          when 1; :wpa
          when 2; :wpa2
          when 3; :wep
        end
        break
      else
        apno = apno.to_i
        if apno > 0 && apno <= aplist.size
          config[:ssid], config[:enc] = aplist[apno-1]
          break
        end
      end
    }
    enc = case config[:enc]
    when :none; 0
    when :wpa;  1
    when :wpa2; 2
    when :wep;  3
    else;       0
    end
    ca = [
      "ATID#{config[:ssid]}", # SSID
      "ATEE#{enc}"            # Encription Enale
    ]
    unless config[:enc] == :none
      ca << "ATPK#{input('KEY')}"
    end
    ca << "ATDL0.0.0.0" # Dest. address
    ca << "ATDE0"       # Dest. port
    ca << "ATIP1"       # TCP
    ca << "ATWR"
    res = @wifi.atcmd(ca)
  end

  def configure_ipv4
    dhcp = input_yn('Use DHCP (Y/n)')
    ca = ["ATMA#{dhcp ? 0 : 1}"]  # DHCP/Static
    unless dhcp
      ca << "ATMY#{input('IP address')}"
      ca << "ATMK#{input('Subnet mask')}"
      gw = input('Default gateway', true)
      ca << "ATGW#{gw}" if gw.size > 0
      dns = input('DNS server', true)
      ca << "ATNS#{dns}" if dns.size > 0
    end
    ca << "ATWR"
    res = @wifi.atcmd(ca)
  end

  def show_hard_info
    puts "<< XBee WiFi information >>"
    ca = [
      'ATHS',   # Hardware series
      'ATHV',   # Hardware version
      'ATVR'    # Firmware version
    ]
    res = @wifi.atcmd(ca)
    puts <<EOS
Hardware Series:  0x#{res[0].to_i.to_s(16)}
Hardware Version: 0x#{res[1].to_i.to_s(16)}
Firmware Version: 0x#{res[2].to_i.to_s(16)}
MAC address:      #{@wifi.mac_address}
EOS
  end

  def ping
    puts "<< ping >>"
    fqdn = input('IP address (or FQDN)')
    addr = IPSocket.getaddress(fqdn)
    print "PING #{fqdn}"
    print " (#{addr})" if fqdn != addr
    print ": "
    puts @wifi.ping(addr)
  rescue
    puts "timeout."
  end

  def factory_reset
    if input_yn('Do you really want to reset XBee-WiFi (y/N)', false)
      print "Factory reset in progress ... "
      @wifi.atcmd ['ATRE', 'ATWR']
      puts "done."
    end
  end

  def menu
    loop {
      puts <<EOS
<< WiFi configuration tool >>
S: Show network configuration
W: WiFi setting
I: IPv4 setting
H: XBee WiFi Hardware information
P: ping
F: Factory reset
Q: Quit menu
EOS
      case input.strip.downcase
      when 's'; show_config
      when 'w'; configure_wifi
      when 'i'; configure_ipv4
      when 'h'; show_hard_info
      when 'p'; ping
      when 'f'; factory_reset
      when 'q'; break
      end
    }
  end

  # private

  # input Y/N
  def input_yn(prompt, default=true)
    ans = nil
    while ans.nil?
      print prompt, ' => '
      case gets.chomp.strip.downcase
      when '';  ans = default
      when 'y'; ans = true
      when 'n'; ans = false
      end
    end
    ans
  end

  # input string
  def input(prompt='', accept_empty=false)
    inp = nil
    while inp.nil?
      print prompt, ' => '
      inp = gets.chomp.strip
      inp = nil if inp.size == 0 && !accept_empty
    end
    inp
  end
end
