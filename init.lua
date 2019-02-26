-- FROM official documentation https://nodemcu.readthedocs.io/en/dev/en/upload/

-- load credentials, 'WIFI_SSID' and 'WIFI_PASSWORD' declared and initialize in there
-- Credentials.lua example
-- WIFI_SSID = "wifi_ssid"
-- WIFI_PASSWORD = "wifi_password"
--------------------------------------------------------------------------------------

print("starting up...")

print("load logger.lua")
dofile("logger.lua")

logger = Logger.create()
logger:info("logger ready.")

logger:info("load credentials.lua")
dofile("credentials.lua")

logger:info("initializing log")


function startup()
    if file.open("init.lua") == nil then
        logger:info("detect init.lua deleted or renamed. stop.")
    else
        file.close("init.lua")

		-- the actual application is stored in 'application.lua'
        if file.exists("main.lua") then
          logger:info("Running application")
          dofile("main.lua")
        else
          logger:warn("no main.lua file. exiting...")
        end
    end
end

-- Define WiFi station event callbacks
wifi_connect_event = function(T)
  logger:info("Connection to AP("..T.SSID..") established!")
  logger:info("Waiting for IP address...")
  if disconnect_ct ~= nil then disconnect_ct = nil end
end

wifi_got_ip_event = function(T)
  -- Note: Having an IP address does not mean there is internet access!
  -- Internet connectivity can be determined with net.dns.resolve().
  logger:info("Wifi connection is ready! IP address is: "..T.IP)
  logger:info("Startup will resume momentarily, you have 3 seconds to abort.")
  logger:info("Waiting... ")
  tmr.create():alarm(10, tmr.ALARM_SINGLE, startup)
end

wifi_disconnect_event = function(T)
  if T.reason == wifi.eventmon.reason.ASSOC_LEAVE then
    --the station has disassociated from a previously connected AP
    return
  end
  -- total_tries: how many times the station will attempt to connect to the AP. Should consider AP reboot duration.
  local total_tries = 75
  logger:info("\nWiFi connection to AP("..T.SSID..") has failed!")

  --There are many possible disconnect reasons, the following iterates through
  --the list and returns the string corresponding to the disconnect reason.
  for key,val in pairs(wifi.eventmon.reason) do
    if val == T.reason then
      logger:info("Disconnect reason: "..val.."("..key..")")
      break
    end
  end

  if disconnect_ct == nil then
    disconnect_ct = 1
  else
    disconnect_ct = disconnect_ct + 1
  end
  if disconnect_ct < total_tries then
    logger:info("Retrying connection...(attempt "..(disconnect_ct+1).." of "..total_tries..")")
  else
    wifi.sta.disconnect()
    logger:info("Aborting connection to AP!")
    disconnect_ct = nil
  end
end

-- Register WiFi Station event callbacks
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, wifi_connect_event)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_got_ip_event)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_disconnect_event)

logger:info("Connecting to WiFi access point...")
wifi.setmode(wifi.STATION)
wifi.sta.config({ssid=WIFI_SSID, pwd=WIFI_PASSWORD})
-- wifi.sta.connect() not necessary because config() uses auto-connect=true by default
