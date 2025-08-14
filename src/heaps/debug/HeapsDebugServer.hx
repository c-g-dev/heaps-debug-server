package heaps.debug;

import heaps.debug.server.endpoints.GetSceneDom2D;
import h2d.Object;
import h2d.Scene;
import haxe.Json;
import StringBuf;
import haxe.io.Bytes;
import StringTools;
import sys.net.Host;
import sys.net.Socket;
import sys.thread.Thread;

typedef HeapsDebugRequest = {
	var method:String;
	var path:String;
	var headers:Map<String,String>;
	var body:String;
}

typedef HeapsDebugResponse = {
	var status:Int;
	var contentType:String;
	var body:String;
}


typedef SceneObjectRegistry = {
    var idToObject: Map<String, h2d.Object>;
    var objectToId: Map<h2d.Object, String>;
}

interface IHeapsDebugEndpoint {
    public var method(default, null): String;
    public var path(default, null): String;
    public function handle(server: HeapsDebugServer, req: HeapsDebugRequest): HeapsDebugResponse;
}


class HeapsDebugServer {
    static var instance: HeapsDebugServer;
    static var routes: Map<String, IHeapsDebugEndpoint> = new Map();

    static var appRef: hxd.App;

    static var lastScene2DRegistry: SceneObjectRegistry;

    var port: Int;
    var listenHost: String;
    var listenSocket: Socket;
    var serverThread: Thread;

    public function new(app: hxd.App, port: Int, host: String) {
        appRef = app;
        this.port = port;
        this.listenHost = host;
    }

    
    public static function attach(app: hxd.App, port: Int = 8025, host: String = "127.0.0.1"): Void {
        if (instance == null) {
            instance = new HeapsDebugServer(app, port, host);
            instance.start(app);
        }
    }

    
    public static function registerEndpoint(endpoint: IHeapsDebugEndpoint): Void {
        var key = endpoint.method + " " + endpoint.path;
        routes.set(key, endpoint);
    }

    
    public static inline function getApp(): hxd.App {
        return appRef;
    }

    
    public static inline function setLastScene2DRegistry(registry: SceneObjectRegistry): Void {
        lastScene2DRegistry = registry;
    }

    
    public static inline function getLastScene2DRegistry(): SceneObjectRegistry {
        if(lastScene2DRegistry == null) {
            
            var sr = GetSceneDom2D.getRegistry();
            lastScene2DRegistry = sr.registry;
        }
        return lastScene2DRegistry;
    }

    
    function start(app: hxd.App): Void {
        initDefaultEndpoints();

        listenSocket = new Socket();
        var host = new Host(listenHost);
        listenSocket.bind(host, port);
        listenSocket.listen(50);

        serverThread = Thread.create(handleAcceptLoop);
    }

    
    public static function stop(): Void {
        if (instance != null) {
            instance.shutdown();
            instance = null;
        }
    }

    function shutdown(): Void {
        if (listenSocket != null) listenSocket.close();
    }

    function handleAcceptLoop(): Void {
        while (true) {
            var client = listenSocket.accept();
            if (client == null) continue;
            Thread.create(function() handleClient(client));
        }
    }

    function handleClient(client: Socket): Void {
        var req = readRequest(client);
        var res = routeRequest(req);
        writeResponse(client, res);
        client.close();
    }

    function readRequest(client: Socket): HeapsDebugRequest {
        var input = client.input;
        var requestLine = input.readLine();
        var parts = requestLine.split(" ");
        var method = parts[0];
        var rawPath = parts[1];
        var qIdx = rawPath.indexOf("?");
        var path = qIdx >= 0 ? rawPath.substr(0, qIdx) : rawPath;

        var headers: Map<String,String> = new Map();
        while (true) {
            var line = input.readLine();
            if (line == null || line == "") break;
            var idx = line.indexOf(":");
            if (idx > 0) {
                var key = StringTools.trim(line.substr(0, idx));
                var value = StringTools.trim(line.substr(idx + 1));
                headers.set(key.toLowerCase(), value);
            }
        }

        var body = "";
        if (headers.exists("content-length")) {
            var len = Std.parseInt(headers.get("content-length"));
            if (len > 0) {
                body = input.readString(len);
            }
        }

        return {
            method: method,
            path: path,
            headers: headers,
            body: body
        };
    }

    function routeRequest(req: HeapsDebugRequest): HeapsDebugResponse {
        var key = req.method + " " + req.path;
        if (routes.exists(key)) {
            return routes.get(key).handle(this, req);
        } else {
            return {
                status: 404,
                contentType: "text/plain; charset=utf-8",
                body: "Not found"
            };
        }
    }

    function writeResponse(client: Socket, res: HeapsDebugResponse): Void {
        var output = client.output;
        var bodyBytes = haxe.io.Bytes.ofString(res.body);
        var sb = new StringBuf();
        sb.add("HTTP/1.1 "); sb.add(Std.string(res.status)); sb.add(" "); sb.add(statusText(res.status)); sb.add("\r\n");
        sb.add("Content-Type: "); sb.add(res.contentType); sb.add("\r\n");
        sb.add("Content-Length: "); sb.add(Std.string(bodyBytes.length)); sb.add("\r\n");
        sb.add("Connection: close\r\n");
        sb.add("\r\n");
        output.writeString(sb.toString());
        output.write(bodyBytes);
        output.flush();
    }

    function statusText(code: Int): String {
        return switch (code) {
            case 200: "OK";
            case 400: "Bad Request";
            case 404: "Not Found";
            case 500: "Internal Server Error";
            default: "OK";
        };
    }

    function initDefaultEndpoints(): Void {
        
        heaps.debug.server.endpoints.GetSceneDom2D.register();
        heaps.debug.server.endpoints.Dashboard.register();
        heaps.debug.server.endpoints.EvalHScript.register();
        heaps.debug.server.endpoints.ServeUI.register();
        heaps.debug.server.endpoints.HighlightObject.register();
        heaps.debug.server.endpoints.ClearHighlight.register();
    }
}

