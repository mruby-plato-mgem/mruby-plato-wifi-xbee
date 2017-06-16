# PlatoDevice::XBeeWiFi class

class Ser
  include Plato::Serial
  attr_accessor :indata
  attr_reader :outdata
  def initialize(baud, dbits=8, start=1, stop=1, parity=:none)
    @indata = []
    @outdata = ''
  end
  def _read
    d = @indata.shift
    d.nil? ? -1 : d
  end
  def _write(v)
    @outdata << v.chr
  end
  def available; @indata.size; end
  def flush; @outdata = ''; end
  def close; end
end
module PlatoDevice
  class XBeeWiFi
    attr_reader :wifi
  end
end

assert('XBeeWiFi', 'class') do
  assert_equal(PlatoDevice::XBeeWiFi.class, Class)
end

assert('XBeeWiFi', 'superclass') do
  assert_equal(PlatoDevice::XBeeWiFi.superclass, Plato::WiFi)
end

assert('XBeeWiFi', 'new') do
  assert_nothing_raised {
    Plato::Serial.register_device(Ser)
    PlatoDevice::XBeeWiFi.new
  }
end

assert('XBeeWiFi', 'new - no device') do
  Plato::Serial.register_device(nil)
  assert_raise(RuntimeError) {PlatoDevice::XBeeWiFi.new}
end

assert('XBeeWiFi', 'open') do
  assert_nothing_raised {
    Plato::Serial.register_device(Ser)
    PlatoDevice::XBeeWiFi.open
  }
end

assert('XBeeWiFi', '_read') do
  Plato::Serial.register_device(Ser)
  wf = PlatoDevice::XBeeWiFi.open
  wf.wifi.indata = [0, 255]
  assert_equal(wf._read, 0)
  assert_equal(wf._read, 255)
  assert_equal(wf._read, -1)
end

assert('XBeeWiFi', '_write') do
  Plato::Serial.register_device(Ser)
  wf = PlatoDevice::XBeeWiFi.open
  wf._write(0)
  wf._write(64)
  wf._write(1)
  assert_equal(wf.wifi.outdata, "\0\100\1")
end

assert('XBeeWiFi', 'available') do
  Plato::Serial.register_device(Ser)
  wf = PlatoDevice::XBeeWiFi.open
  assert_equal(wf.available, 0)
  wf.wifi.indata = [1, 2]
  assert_equal(wf.available, 2)
end

assert('XBeeWiFi', 'flush') do
  assert_nothing_raised {
    Plato::Serial.register_device(Ser)
    wf = PlatoDevice::XBeeWiFi.open
    wf.flush
  }
end

assert('XBeeWiFi', 'close') do
  assert_nothing_raised {
    Plato::Serial.register_device(Ser)
    wf = PlatoDevice::XBeeWiFi.open
    wf.close
  }
end
