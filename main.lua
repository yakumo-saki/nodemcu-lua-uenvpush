
-- HTTP readable BME280
bme_temp = 0
bme_pres = 0
bme_humi = 0
bme_alt = 0

itemsPublished = 0

function publishCallback()
	itemsPublished = (itemsPublished or 0) + 1
	print("items published " .. itemsPublished)

	if (itemsPublished >= mqtt_send_count) then
		print("All done!! go to deep sleep for " .. dsleep_duration .. "us")
		m:close()
		node.dsleep(dsleep_duration)
		tmr.delay(10000)  -- this maybe not execute
	end
end   

function read_bme()
	print("reading bme280(read)")
	T, P, H, QNH = bme280.read(alt)
	if (T ~= nil) then
		local Tsgn = (T < 0 and -1 or 1); T = Tsgn*T
		print(string.format("T=%s%d.%02d", Tsgn<0 and "-" or "", T/100, T%100))
		print(string.format("QFE=%d.%03d", P/1000, P%1000))
		print(string.format("QNH=%d.%03d", QNH/1000, QNH%1000))
		print(string.format("humidity=%d.%03d%%", H/1000, H%1000))

		-- 露天温度 deapoint
		D = bme280.dewpoint(H, T)
		local Dsgn = (D < 0 and -1 or 1); D = Dsgn*D
		print(string.format("dew_point=%s%d.%02d", Dsgn<0 and "-" or "", D/100, D%100))

		local temp_sign = Tsgn < 0 and -1 or 1
		-- bme_temp = (T/100)    -- + (T%100)
		-- bme_pres = (QNH/1000) -- + (QNH%1000)
		-- bme_humi = (H/1000)   -- + (H%1000)
		bme_temp = string.format("%s%d.%02d", Tsgn<0 and "-" or "", T/100, T%100)
		bme_pres = string.format("%d.%03d", QNH/1000, QNH%1000)
		bme_humi = string.format("%d.%03d", H/1000, H%1000)
	end

	-- altimeter function - calculate altitude based on current sea level pressure (QNH) and measure pressure
	print("reading bme280 (baro)")
	P = bme280.baro()
	if (P ~= nil) then
		curAlt = bme280.altitude(P, QNH)
		local curAltsgn = (curAlt < 0 and -1 or 1); curAlt = curAltsgn*curAlt
		bme_alt = curAlt
		print(string.format("altitude=%s%d.%02d", curAltsgn<0 and "-" or "", curAlt/100, curAlt%100))
	end
end

print("Loading config")
dofile('config')

print("initializing I2C")
i2c.setup(0, sda, scl, i2c.SLOW) -- call i2c.setup() only once

print("initializing BME280 or BMP280")
sensor_type = nil
while (sensor_type == nil) do
  tmr.delay(500 * 1000)
	sensor_type = bme280.setup()
	
	if sensor_type == nil then
		print("BMx280 sensor setup failed. retry.")
	end
end

if sensor_type == 1 then
	print("sensor is BMP280")
elseif sensor_type == 2 then
	print("sensor is BME280")
end

print('read BME')
tmr.delay(500)
read_bme()

-- init mqtt client without logins, keepalive timer 120s
m = mqtt.Client(mqtt_client_name, 120)

-- m:on("connect", function(client) print ("connected") end)
-- m:on("offline", function(client) print ("offline") end)

-- on publish overflow receive event
m:on("overflow", function(client, topic, data)
  print(topic .. " partial overflowed message: " .. data )
end)

m:connect(mqtt_broker, mqtt_broker_port, 0, function(client)
		print("connected")

		-- mqtt:publish(topic, payload, qos, retain[, function(client)])
		print("send " .. mqtt_topic_temp .. "=>" .. bme_temp)
		client:publish(mqtt_topic_temp, bme_temp, 0, 0, publishCallback)
		print("send " .. mqtt_topic_humi .. "=>" .. bme_humi)
		client:publish(mqtt_topic_humi, bme_humi, 0, 0, publishCallback)
		print("send " .. mqtt_topic_pres .. "=>" .. bme_pres)
		client:publish(mqtt_topic_pres, bme_pres, 0, 0, publishCallback)
		print("send done.")
	end,
	function(client, reason)
		print("failed reason: " .. reason)
		if reason == -5 then
			print("mqtt.CONN_FAIL_SERVER_NOT_FOUND")
		elseif reason == -4 then
			print("mqtt.CONN_FAIL_NOT_A_CONNACK_MSG")
		elseif reason == -3 then
			print("mqtt.CONN_FAIL_DNS")
		elseif reason == -2 then
			print("mqtt.CONN_FAIL_TIMEOUT_RECEIVING")
		elseif reason == -1 then
			print("mqtt.CONN_FAIL_TIMEOUT_SENDING")
		elseif reason == 0 then
			print("mqtt.CONNACK_ACCEPTED.  this is not error")
		elseif reason == 1 then
			print("mqtt.CONNACK_REFUSED_PROTOCOL_VER")
		elseif reason == 2 then
			print("mqtt.CONNACK_REFUSED_ID_REJECTED")
		elseif reason == 3 then
			print("mqtt.CONNACK_REFUSED_SERVER_UNAVAILABLE")
		elseif reason == 4 then
			print("mqtt.CONNACK_REFUSED_BAD_USER_OR_PASS")
		elseif reason == 5 then
			print("mqtt.CONNACK_REFUSED_NOT_AUTHORIZED")
		end
end)

