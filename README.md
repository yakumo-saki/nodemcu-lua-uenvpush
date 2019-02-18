# nodemcu-display

ESP8266 JSON temperature and humidity meter

## これは何？
http経由で表示を変更できるディスプレイです。

## nodemcu build

* modules: bme280 file gpio http i2c mdns net node sjson sntp tmr tsl2561 uart wifi
* floatを使うのでfloat版を入れてください

## artifacts not by me
* httpServer.lua - https://github.com/wangzexi/NodeMCU-HTTP-Server

## ファイル転送方法
`nodemcu-tool` をインストール

```
nodemcu-tool --port /dev/tty.portname upload *.lua
```

## WebAPI

### clear

#### パラメタ
なし

#### 機能
画面を消去します

#### サンプル
curl http://dumbdisplay.local/clear

### string
画面を消去します

#### パラメタ

1. text （必須）表示文字列
1. x （必須）x座標
1. y （必須）y座標
1. direction （省略可） 文字を描画する方向 0 左から右（デフォルト） 1 90度右 2 180度 3 270度
1. fontsize （省略可） xl 特大 l 大 （それ以外）標準（デフォルト）
1. fontmode （省略可）フォント描画モード
1. fontcolor（省略可）フォント色

#### 機能
画面を消去します

#### サンプル

```
curl http://dumbdisplay.local/clear
```


