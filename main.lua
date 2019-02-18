
-- HTTP readable BME280
bme_temp = 0
bme_pres = 0
bme_humi = 0
bme_alt = 0

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

print("i2c scan")
for i=0,127 do
	i2c.start(id)
	resCode = i2c.address(id, i, i2c.TRANSMITTER)
	i2c.stop(id)
	if resCode == true then print("We have a device on address 0x" .. string.format("%02x", i) .. " (" .. i ..")") end
end

print("end i2c scan")

print("initializing BME280 or BMP280")
sensor_type = nil
while (sensor_type == nil) do
	sensor_type = bme280.setup()
	print("sensor setup failed. retry.")
	tmr.delay(1000 * 1000)
end

if sensor_type == 1 then
	print("sensor is BMP280")
elseif sensor_type == 2 then
	print("sensor is BME280")
end

print("HTTP server start")
dofile('httpServer.lua')
httpServer:listen(80)

print("HTTP GET / Handler setup")
dofile('handleGet.lua')

print('mdns start hostname=' .. mdns_name)
mdns.register(mdns_name, { description="dumb_display", service="http", port=80, location='Living Room' })

print('first read BME')
tmr.delay(3000)
read_bme()

print('start timer')
mytimer = tmr.create()
mytimer:register(3000, tmr.ALARM_AUTO, function() read_bme() end)
mytimer:start()
