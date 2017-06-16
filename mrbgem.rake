MRuby::Gem::Specification.new('mruby-plato-wifi-xbee') do |spec|
  spec.license = 'MIT'
  spec.authors = 'Plato developers'
  spec.description = 'PlatoDevice::XBeeWiFi class (XBee Pro Wi-Fi device class)'

  spec.add_dependency('mruby-plato-machine')
  spec.add_test_dependency('mruby-plato-machine-sim')
  spec.add_dependency('mruby-plato-serial')
  spec.add_dependency('mruby-plato-wifi')
end
