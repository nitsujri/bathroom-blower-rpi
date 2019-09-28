require 'rpi_gpio'

# Pins
RELAY_1 = 3
RELAY_2 = 5
PIR_PIN = 7

# Globals

def setup
  RPi::GPIO.set_numbering :board

  RPi::GPIO.setup PIR_PIN, as: :input

  RPi::GPIO.setup RELAY_1, as: :output
  RPi::GPIO.setup RELAY_2, as: :output
end

def loop
  if RPi::GPIO.high? PIR_PIN
    set_relays 'high'
  else
    set_relays 'low'
  end

end

def set_relays(output)
  [RELAY_1, RELAY_2].each do |relay|
    RPi::GPIO.send("set_#{output}", relay)
  end
end

#### Run Program ####
setup
while(true) do
  loop
end
