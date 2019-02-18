-- Custom API
-- Get text/html
httpServer:use('/', function(req, res)
	print(bme_temp)
	print(bme_humi)
	print(bme_pres)
	json = '{'
	json = json .. '"temparature": "' .. bme_temp .. '",'
	json = json .. '"humidity": "' .. bme_humi .. '",'
	json = json .. '"pressure": "' .. bme_pres .. '"'
	json = json .. '}'
	print(json)
	res:send(json)
end)

