module CommandLineLogger
  def self.create
    logger = Logger.new($stderr)
    logger.formatter = proc { |severity, datetime, progname, msg|
      "update-messages: #{msg}\n"
    }
    logger.level = :info

    logger
  end
end
