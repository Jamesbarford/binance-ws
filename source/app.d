module ex;

import std.stdio;
import core.memory;
import std.json;
import std.conv;
import std.array;
import std.algorithm;
import core.stdc.stdlib;
import core.sys.posix.unistd;
import vibe.vibe;

private const string BINANCE_URL = "wss://stream.binance.com:9443/stream?streams=";

void printUsage() {
    stderr.writeln("Usage: wsbinance [OPTIONS]\n" ~
            "  Simple websocket client for connecting to a kline stream and printing\n" ~
            "  the output to stdout.\n\n" ~
            "  --symbols <string>  A csv of coin symbols to track. Example: btcgbp,ethgbp or btcgbp"
        );
    exit(EXIT_FAILURE);
}

WebSocket wsConnect(string url) {
    return connectWebSocket(URL(url));
}

void wsMain(WebSocket ws) {
    while (ws.waitForData()) {
        auto txt = ws.receiveText;

        try {
            auto j = parseJSON(txt);
            // sometimes this comes though: {"result":null,"id":<int>}
            if ("result" in j) continue;
            writeln(j.toPrettyString());
        } catch(Exception e) {
            stderr.writefln("Failed to parse json %s", e);
            ws.close(WebSocketCloseReason.internalError);
        }
    }
}

string binanceCreateUrl(string[] symbols) {
    return BINANCE_URL ~ reduce!((a, b) => a ~= "/" ~ b)(symbols);
}

string binanceCreatePayload(string[] symbols) {
    string payload = `{"method":"SUBSCRIBE","params":[`;

    for (int i = 0; i < symbols.length; ++i) {
        if (i + 1 == symbols.length) {
            payload ~= '"' ~ symbols[i] ~ '"';
        } else {
            payload ~= '"' ~ symbols[i] ~ '"' ~ ',';
        }
    }
    
    payload ~= `],"id":1}`;

    return payload;
}

string[] parseCmdArgs(string []argv) {
    for (int i = 0; i < argv.length; ++i) {
        if (argv[i] == "--symbols") {
            return argv[i + 1].split(",");
        }
    }

    return null;
}

void main(string []argv) {
    string []symbols = parseCmdArgs(argv);

    if (symbols == null) printUsage();

    string url = binanceCreateUrl(symbols);
    string payload = binanceCreatePayload(symbols);
    WebSocket ws = wsConnect(url);
    ws.send(payload);

    wsMain(ws);
    scope(exit) {
        ws.close();
    }
}
