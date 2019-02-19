# nodemcu-lua-uenvpush

ESP8266 MQTT temperature and humidity meter

## これは何？

BME280から取得した温度・湿度・気圧をMQTTにpublishします。

## nodemcu build

* modules: bme280 file gpio http i2c mdns net node sjson sntp tmr tsl2561 uart wifi
* floatを使うのでfloat版を入れてください

## ファイル転送方法
`nodemcu-tool` をインストール

```
nodemcu-tool --port /dev/tty.portname upload config
nodemcu-tool --port /dev/tty.portname upload *.lua
```
