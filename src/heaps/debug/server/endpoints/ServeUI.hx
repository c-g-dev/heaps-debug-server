package heaps.debug.server.endpoints;

import heaps.debug.HeapsDebugServer;
import heaps.debug.HeapsDebugServer.IHeapsDebugEndpoint;
import heaps.debug.HeapsDebugServer.HeapsDebugRequest;
import heaps.debug.HeapsDebugServer.HeapsDebugResponse;
import sys.io.File;

class ServeUI implements IHeapsDebugEndpoint {
	public var method(default, null): String = "GET";
	public var path(default, null): String = "/ui.js";

	public static function register(): Void {
		HeapsDebugServer.registerEndpoint(new ServeUI());
	}

	public function new() {}

	public function handle(server: HeapsDebugServer, req: HeapsDebugRequest): HeapsDebugResponse {
		var js = File.getContent("bin/ui.js");
		return {
			status: 200,
			contentType: "application/javascript; charset=utf-8",
			body: js
		};
	}
}


