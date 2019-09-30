module BlowerLogging
  attr_reader :logger

  def log_fan(state)
    return if state == previous_fan_state

    @logger.info("Fan has turned #{state == BathroomBlower::ON ? 'ON' : 'OFF'}")
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
