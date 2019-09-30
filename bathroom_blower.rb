require 'fileutils'
require 'logger'
require 'rpi_gpio'

require_relative './blower_logging'

class BathroomBlower
  include BlowerLogging

  MOTION_STAY_ON = 3 * 60
  OVERRIDE_TIME = 15 * 60

  # Pins
  RELAY_1 = 3
  RELAY_2 = 5
  PIR_PIN = 7
  OVERRIDE_PIN = 11

  ON = true
  OFF = false

  attr_reader(
    :previous_fan_state,    # Holds the last state change, only updated on change
    :motion_detected_at,
    :override_toggled_at,
    :override_output,       # Carries absolute override output, set when button pressed
    :current_fan_state      # Set just after actually setting relays
  )

  def initialize
    @fan_state = OFF
    @override_toggled_at = @motion_detected_at = Time.new(1,1,1,1)

    setup_logger

    setup_board
    setup_pins
    setup_events

    @logger.info 'Starting Fan program ================='
  end

  def run!
    fan_state = motion_detected? || fumigation_running?

    fan_state = override_output if override?

    fan_power(fan_state)
  end

  private

  def detected_motion
    @motion_detected_at = Time.now

    @logger.info 'Motion DETECTED'
  end

  def detected_override
    @override_toggled_at = Time.now
    @override_output = !current_fan_state

    @logger.info 'Override TOGGLED'
  end

  def motion_detected?
    time_now = Time.now

    # Motion lockout time 10pm - 7am
    return OFF if time_now.hour.between?(22, 24) || time_now.hour.between?(0, 7)

    return ON if motion_detected_at + MOTION_STAY_ON > time_now

    OFF
  end

  def fumigation_running?
    time_now = Time.now

    return ON if (
      ( # Weekdays, 7-9AM, 3-10pm, every 30 minutes, for 30s
        time_now.sec.between?(0, 30) &&
        [00, 30].include?(time_now.min) &&
        (time_now.hour.between?(7, 9) || time_now.hour.between?(15, 22)) &&
        ['MON','TUE','WED','THU','FRI'].include?(time_now.strftime('%^a'))
      ) ||
      ( # Weekends, 7am-10pm, every 30 minutes, for 30s
        time_now.sec.between?(0, 30) &&
        [00, 30].include?(time_now.min) &&
        (time_now.hour.between?(7, 22)) &&
        ['SAT', 'SUN'].include?(time_now.strftime('%^a'))
      )
    )

    OFF
  end

  def override?
    return true if override_toggled_at + OVERRIDE_TIME > Time.now

    false
  end

  # Primary board output
  def fan_power(state)
    [RELAY_1, RELAY_2].each do |relay|
      # Flip the state because that's how the Relays work
      output = state == ON ? 'low' : 'high'

      RPi::GPIO.send("set_#{output}", relay)
    end

    @current_fan_state = state
    log_fan(state)
  end

  ###### Setup Functions

  def setup_board
    RPi::GPIO.reset
    @logger.info 'GPIO Board reset ====================='
  end

  def setup_events
    RPi::GPIO.add_edge_detect PIR_PIN, RPi::GPIO.RISING
    RPi::GPIO.add_edge_detect OVERRIDE_PIN, RPi::GPIO.RISING

    RPi::GPIO.add_edge_callback PIR_PIN, detected_motion
    RPi::GPIO.add_edge_callback OVERRIDE_PIN, detected_override

    @logger.info 'Events Added ========================='
  end

  def setup_pins
    RPi::GPIO.set_numbering :board

    RPi::GPIO.setup PIR_PIN, as: :input, pull: :down
    RPi::GPIO.setup OVERRIDE_PIN, as: :input, pull: :down

    RPi::GPIO.setup RELAY_1, as: :output, initialize: :low
    RPi::GPIO.setup RELAY_2, as: :output, initialize: :low

    @logger.info 'Pins setup ==========================='
  end
end
