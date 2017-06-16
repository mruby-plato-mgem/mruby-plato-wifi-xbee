# mruby-plato-wifi-xbee   [![Build Status](https://travis-ci.org/mruby-plato/mruby-plato-wifi-xbee.svg?branch=master)](https://travis-ci.org/mruby-plato/mruby-plato-wifi-xbee)
PlatoDevice::XBeeWiFi class (XBee Pro Wi-Fi device class)
## install by mrbgems
- add conf.gem line to `build_config.rb`

```ruby
MRuby::Build.new do |conf|

  # ... (snip) ...

  conf.gem :git => 'https://github.com/mruby-plato/mruby-plato-machine'
  conf.gem :git => 'https://github.com/mruby-plato/mruby-plato-serial'
  conf.gem :git => 'https://github.com/mruby-plato/mruby-plato-wifi'
end
```

## example
```ruby
wf = PlatoDevice::XBeeWiFi.open(9600)
wf.puts "Hello, Plato!"
```

## License
under the MIT License:
- see LICENSE file
