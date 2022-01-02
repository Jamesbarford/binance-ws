# Binance WS

Very simple binance command line websocket client.

## Build

```sh
dub build
```

## Usage
```
Usage: wsbinance [OPTIONS]

Simple websocket client for connecting to a kline stream and printing
the output to stdout or saving the data in a file.

  --symbols <string>   A csv of coin symbols to track. Example: btcgbp,ethgbp or btcgbp
  --out-file <string>  Name of a file to write the contents out to
```

