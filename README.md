# nodemcu-lua-uenvpush

ESP8266 MQTT temperature and humidity meter

## これは何？

BME280から取得した温度・湿度・気圧をMQTTにpublishします。

## nodemcu build

* modules: bme280 file gpio http i2c mdns net node sjson sntp tmr tsl2561 uart wifi
* floatを使うのでfloat版を入れてください

## usage

config を編集して自分の環境に合わせて下さい。

## ファイル転送方法

`nodemcu-tool` をインストールして以下のコマンド

```
nodemcu-tool --port /dev/tty.portname upload config
nodemcu-tool --port /dev/tty.portname upload *.lua
```
