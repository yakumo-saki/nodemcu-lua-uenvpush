dofile('logger.lua')

logger = Logger.create()

-- normal output
logger:debug("debug test")
logger:info("info test")
logger:warn("warn test")
logger:error("error test")

-- additional handler
logger:add_extra_handler(function(msg) print("ADDITIONAL " .. msg) end)
logger:debug("ext debug test")
logger:info("ext info test")
logger:warn("ext warn test")
logger:error("ext error test")
