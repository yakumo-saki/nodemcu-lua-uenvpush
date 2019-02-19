-- http://www.esp8266.com/viewtopic.php?f=19&t=771
-- Scan for I2C devices
-- FOR DEBUG PURPOSE ONLY. NOT USED IN MAIN CODE

id=0

sda, scl = 1, 2

-- initialize i2c, set pin1 as sda, set pin0 as scl

print("i2c setup sda=" .. sda .. " scl=" .. scl)
i2c.setup(id,sda,scl,i2c.SLOW)

for x=0,5 do
	print("i2c scan sda=" .. sda .. " scl=" .. scl)

	for i=0,127 do
		i2c.start(id)
		resCode = i2c.address(id, i, i2c.TRANSMITTER)
		i2c.stop(id)
		if resCode == true then print("count=" .. x .. " We have a device on address 0x" .. string.format("%02x", i) .. " (" .. i ..")") end
	end

	tmr.delay(300 * 1000)
end

print("end")
