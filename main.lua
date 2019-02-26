
-- HTTP readable BME280
bme_temp = 0
bme_pres = 0
bme_humi = 0
bme_alt = 0

itemsPublished = 0

function publishCallback()
	itemsPublished = (itemsPublished or 0) + 1
	logger:info("items published " .. itemsPublished)

	if (itemsPublished >= mqtt_send_count) then
		logger:info("Watchdog stop.")
		watchdog:stop()

		logger:info("All done!! go to deep sleep for " .. dsleep_duration .. "us")
		m:close()
		tmr.delay(100)  -- this maybe not execute
		node.dsleep(dsleep_duration)		
	end
end   

function read_bme()
	logger:info("reading bme280(read)")
	T, P, H, QNH = bme280.read(alt)
	if (T ~= nil) then
		local Tsgn = (T < 0 and -1 or 1); T = Tsgn*T
		logger:info(string.format("T=%s%d.%02d", Tsgn<0 and "-" or "", T/100, T%100))
		logger:info(string.format("QFE=%d.%03d", P/1000, P%1000))
		logger:info(string.format("QNH=%d.%03d", QNH/1000, QNH%1000))
		logger:info(string.format("humidity=%d.%03d%%", H/1000, H%1000))

		-- 露天温度 deapoint
		D = bme280.dewpoint(H, T)
		local Dsgn = (D < 0 and -1 or 1); D = Dsgn*D
		logger:info(string.format("dew_point=%s%d.%02d", Dsgn<0 and "-" or "", D/100, D%100))

		local temp_sign = Tsgn < 0 and -1 or 1
		-- bme_temp = (T/100)    -- + (T%100)
		-- bme_pres = (QNH/1000) -- + (QNH%1000)
		-- bme_humi = (H/1000)   -- + (H%1000)
		bme_temp = string.format("%s%d.%02d", Tsgn<0 and "-" or "", T/100, T%100)
		bme_pres = string.format("%d.%03d", QNH/1000, QNH%1000)
		bme_humi = string.format("%d.%03d", H/1000, H%1000)
	end

	-- altimeter function - calculate altitude based on current sea level pressure (QNH) and measure pressure
	logger:info("reading bme280 (baro)")
	P = bme280.baro()
	if (P ~= nil) then
		curAlt = bme280.altitude(P, QNH)
		local curAltsgn = (curAlt < 0 and -1 or 1); curAlt = curAltsgn*curAlt
		bme_alt = curAlt
		logger:info(string.format("altitude=%s%d.%02d", curAltsgn<0 and "-" or "", curAlt/100, curAlt%100))
	end
end

logger:info("Watchdog timer set")
watchdog = tmr.create()
watchdog:register(1000, tmr.ALARM_SINGLE, function(t) 
	logger.error("watchdog timer hit. go to deep sleep")
	logger:info("go to deep sleep for " .. dsleep_duration .. "us")
	node.dsleep(dsleep_duration)		
end)
watchdog:start()

logger:info("Loading config")
dofile('config')

logger:info("initializing I2C")
i2c.setup(0, sda, scl, i2c.SLOW) -- call i2c.setup() only once

logger:info("initializing BME280 or BMP280")
sensor_type = nil
while (sensor_type == nil) do
	sensor_type = bme280.setup()
	
	if sensor_type == nil then
		logger:info("BMx280 sensor setup failed. retry.")
		tmr.delay(500 * 1000)
	end
end

if sensor_type == 1 then
	logger:info("sensor is BMP280")
elseif sensor_type == 2 then
	logger:info("sensor is BME280")
end

logger:info('read BME')
tmr.delay(500)
read_bme()

-- init mqtt client without logins, keepalive timer 120s
m = mqtt.Client(mqtt_client_name, 120)

-- m:on("connect", function(client) logger:info ("connected") end)
-- m:on("offline", function(client) logger:info ("offline") end)

-- on publish overflow receive event
m:on("overflow", function(client, topic, data)
  logger:info(topic .. " partial overflowed message: " .. data )
end)

m:connect(mqtt_broker, mqtt_broker_port, 0, function(client)
		logger:info("connected")

		-- mqtt:publish(topic, payload, qos, retain[, function(client)])
		logger:info("send " .. mqtt_topic_temp .. "=>" .. bme_temp)
		client:publish(mqtt_topic_temp, bme_temp, 0, 0, publishCallback)
		logger:info("send " .. mqtt_topic_humi .. "=>" .. bme_humi)
		client:publish(mqtt_topic_humi, bme_humi, 0, 0, publishCallback)
		logger:info("send " .. mqtt_topic_pres .. "=>" .. bme_pres)
		client:publish(mqtt_topic_pres, bme_pres, 0, 0, publishCallback)
		logger:info("send done.")
	end,
	function(client, reason)
		logger:info("failed reason: " .. reason)
		if reason == -5 then
			logger:error("mqtt.CONN_FAIL_SERVER_NOT_FOUND")
		elseif reason == -4 then
			logger:error("mqtt.CONN_FAIL_NOT_A_CONNACK_MSG")
		elseif reason == -3 then
			logger:error("mqtt.CONN_FAIL_DNS")
		elseif reason == -2 then
			logger:error("mqtt.CONN_FAIL_TIMEOUT_RECEIVING")
		elseif reason == -1 then
			logger:error("mqtt.CONN_FAIL_TIMEOUT_SENDING")
		elseif reason == 0 then
			logger:error("mqtt.CONNACK_ACCEPTED.  this is not error")
		elseif reason == 1 then
			logger:error("mqtt.CONNACK_REFUSED_PROTOCOL_VER")
		elseif reason == 2 then
			logger:error("mqtt.CONNACK_REFUSED_ID_REJECTED")
		elseif reason == 3 then
			logger:error("mqtt.CONNACK_REFUSED_SERVER_UNAVAILABLE")
		elseif reason == 4 then
			logger:error("mqtt.CONNACK_REFUSED_BAD_USER_OR_PASS")
		elseif reason == 5 then
			logger:error("mqtt.CONNACK_REFUSED_NOT_AUTHORIZED")
		end
end)

