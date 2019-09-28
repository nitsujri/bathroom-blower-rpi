require_relative 'bathroom_blower'

LOOP_SPEED = 0.01 # Seconds

@bb = BathroomBlower.new

#### Run Program ####
loop do
  @bb.run!

  sleep LOOP_SPEED
end
