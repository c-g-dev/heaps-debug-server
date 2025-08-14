package heaps.debug.server.endpoints;

import heaps.debug.HeapsDebugServer;
import heaps.debug.HeapsDebugServer.IHeapsDebugEndpoint;
import heaps.debug.HeapsDebugServer.HeapsDebugRequest;
import heaps.debug.HeapsDebugServer.HeapsDebugResponse;
import heaps.debug.util.RunOnUIThread;
import heaps.debug.util.Highlighter;

class ClearHighlight implements IHeapsDebugEndpoint {
	public var method(default, null): String = "POST";
	public var path(default, null): String = "/highlight/clear";

	public static function register(): Void {
		HeapsDebugServer.registerEndpoint(new ClearHighlight());
	}

	public function new() {}

	public function handle(server: HeapsDebugServer, req: HeapsDebugRequest): HeapsDebugResponse {
		HeapsDebugServer.getApp().s2d.addChild(new RunOnUIThread(() -> {
			Highlighter.clear();
		}));
		return {
			status: 200,
			contentType: "text/plain; charset=utf-8",
			body: "OK"
		};
	}
}


