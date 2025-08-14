package heaps.debug.server.endpoints;

import heaps.debug.HeapsDebugServer;
import heaps.debug.HeapsDebugServer.IHeapsDebugEndpoint;
import heaps.debug.HeapsDebugServer.HeapsDebugRequest;
import heaps.debug.HeapsDebugServer.HeapsDebugResponse;
import sys.io.File;

class Dashboard implements IHeapsDebugEndpoint {
	public var method(default, null): String = "GET";
	public var path(default, null): String = "/dashboard";

	public static function register(): Void {
		HeapsDebugServer.registerEndpoint(new Dashboard());
	}

	public function new() {}

	public function handle(server: HeapsDebugServer, req: HeapsDebugRequest): HeapsDebugResponse {
		var html = File.getContent("bin/dashboard.html");
		
		if (html.indexOf("/ui.js") == -1) {
			var marker = "</body>";
			var idx = html.indexOf(marker);
			if (idx >= 0) {
				html = html.substr(0, idx)
					+ "\n<script src=\"/ui.js\"></script>\n"
					+ html.substr(idx);
			}
		}
		return {
			status: 200,
			contentType: "text/html; charset=utf-8",
			body: html
		};
	}
}

