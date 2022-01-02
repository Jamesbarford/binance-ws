module ex;

import core.memory;
import core.stdc.stdlib;
import core.sys.posix.unistd;
import core.stdc.string;
import core.stdc.errno;

import std.stdio: stderr, writeln;
import std.json;
import std.conv;
import std.array;
import std.algorithm;
import std.file;

import vibe.vibe;

private const string BINANCE_URL = "wss://stream.binance.com:9443/stream?streams=";

void printUsage() {
    stderr.writeln("\nUsage: wsbinance [OPTIONS]\n\n" ~
            "Simple websocket client for connecting to a kline stream and printing\n" ~
            "the output to stdout or saving the data in a file.\n\n" ~
            "  --symbols <string>   A csv of coin symbols to track. Example: btcgbp,ethgbp or btcgbp\n" ~
            "  --out-file <string>  Name of a file to write the contents out to\n"
        );
    exit(EXIT_FAILURE);
}

WebSocket wsConnect(string url) {
    return connectWebSocket(URL(url));
}

void wsMain(WebSocket ws, string out_file) {
    if (out_file)
        append(out_file, "[");

    while (ws.waitForData()) {
        auto txt = ws.receiveText;

        try {
            auto j = parseJSON(txt);
            // sometimes this comes though: {"result":null,"id":<int>}
            if ("result" in j) continue;
            /* store data */
            if (out_file) append(out_file, j.toString() ~ ",");
            /* write to stdout */
            else writeln(j.toPrettyString());
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

string[string] parseCmdArgs(string []argv) {
    string[string] arg_table;

    for (int i = 0; i < argv.length; ++i) {
        switch (argv[i]) {
            case "--symbols":
                arg_table["symbols"] = argv[++i];
                continue;
            case "--out-file":
                arg_table["out_file"] = argv[++i];
                continue;
            default: continue;
        }
    }

    return arg_table;
}

void main(string []argv) {
    string[string] arg_table = parseCmdArgs(argv);

    if (!("symbols" in arg_table)) {
        stderr.write("--symbols must be provided\n");
        printUsage();
        exit(EXIT_FAILURE);
    }

    string []symbols = arg_table["symbols"].split(",");
    string out_file = "out_file" in arg_table ? arg_table["out_file"] : null;

    if (symbols == null) printUsage();

    string url = binanceCreateUrl(symbols);
    string payload = binanceCreatePayload(symbols);
    WebSocket ws = wsConnect(url);
    ws.send(payload);

    wsMain(ws, out_file);
    scope(exit) {
        ws.close();
    }
}
