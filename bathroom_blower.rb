require 'fileutils'
require 'logger'
require 'rpi_gpio'

class BathroomBlower
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
    :logger,
    :previous_fan_state,    # Holds the last state change, only updated on change
    :motion_detected_at,
    :override_toggled_at,
    :override_output,       # Carries absolute override output, set when button pressed
    :current_fan_state      # Set just after actually setting relays
  )

  def initialize
    setup_logger

    @fan_state = OFF
    @override_toggled_at = @motion_detected_at = Time.new(1,1,1,1)

    RPi::GPIO.reset
    @logger.info 'GPIO Board reset ====================='

    RPi::GPIO.set_numbering :board

    RPi::GPIO.setup PIR_PIN, as: :input, pull: :down
    RPi::GPIO.setup OVERRIDE_PIN, as: :input, pull: :down


    RPi::GPIO.setup RELAY_1, as: :output, initialize: :low
    RPi::GPIO.setup RELAY_2, as: :output, initialize: :low

    @logger.info 'Pins setup ==========================='
    @logger.info 'Starting Fan program ================='
  end

  def run!
    fan_state = check_motion || regular_fumigation

    fan_state = override_output if override?

    fan_power(fan_state)
  end

  private

  def check_motion
    time_now = Time.now

    # Motion lockout time 10pm - 7am
    return OFF if time_now.hour.between?(22, 24) || time_now.hour.between?(0, 7)

    # Set latest time seen if there's motion
    if RPi::GPIO.high?(PIR_PIN)
      @motion_detected_at = time_now
      return ON
    end

    return ON if motion_detected_at + MOTION_STAY_ON > time_now

    OFF
  end

  def regular_fumigation
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
    if RPi::GPIO.high?(OVERRIDE_PIN)
      @override_toggled_at = Time.now
      @override_output = !current_fan_state
    end

    return true if override_toggled_at + OVERRIDE_TIME > Time.now

    false
  end

  def fan_power(state)
    [RELAY_1, RELAY_2].each do |relay|
      # Flip the state because that's how the Relays work
      output = state == ON ? 'low' : 'high'

      RPi::GPIO.send("set_#{output}", relay)
    end

    @current_fan_state = state
    log_fan(state)
  end

  def log_fan(state)
    return if state == previous_fan_state

    @logger.info("Fan has turned #{state == ON ? 'ON' : 'OFF'}")
    @previous_fan_state = state
  end

  def setup_logger
    logpath = File.join(__dir__, 'log', 'production.log')
    dir = File.dirname(logpath)

    FileUtils.mkdir_p(dir) unless File.directory?(dir)

    @logger = Logger.new(logpath)
    @logger.level = Logger::INFO
  end
end
