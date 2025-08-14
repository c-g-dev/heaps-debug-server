package heaps.debug.server.endpoints;

import heaps.debug.util.RunOnUIThread;
import heaps.debug.HeapsDebugServer;
import heaps.debug.HeapsDebugServer.IHeapsDebugEndpoint;
import heaps.debug.HeapsDebugServer.HeapsDebugRequest;
import heaps.debug.HeapsDebugServer.HeapsDebugResponse;
import hscript.Parser;
import hscript.Interp;
import haxe.Timer;

class EvalHScript implements IHeapsDebugEndpoint {
	public var method(default, null): String = "POST";
	public var path(default, null): String = "/eval";

	public static function register(): Void {
		HeapsDebugServer.registerEndpoint(new EvalHScript());
	}

	public function new() {}

	public function handle(server: HeapsDebugServer, req: HeapsDebugRequest): HeapsDebugResponse {
		var code = req.body;
		if (code == null || code == "") {
			return {
				status: 400,
				contentType: "text/plain; charset=utf-8",
				body: "Empty request body"
			};
		}

		
		
			HeapsDebugServer.getApp().s2d.addChild(new RunOnUIThread(() -> {
				trace("code: " + code);
				var app = HeapsDebugServer.getApp();
				var parser = new Parser();
				parser.allowTypes = true;
				parser.allowJSON = true;
				var program = parser.parseString(code);
				var interp = new Interp();
				interp.variables.set("app", app);
				interp.variables.set("s2d", app.s2d);
				interp.variables.set("s3d", app.s3d);
				interp.variables.set("scene2d", app.s2d);
				interp.variables.set("scene3d", app.s3d);
				interp.variables.set("Std", Std);
				interp.variables.set("Type", Type);
				
				interp.variables.set("get2d", function(id:String) {
					var reg = HeapsDebugServer.getLastScene2DRegistry();
					trace("reg: " + reg);
					return reg == null ? null : reg.idToObject.get(id);
				});
				
				
				
				interp.execute(program);
			}));
			
	

		return {
			status: 200,
			contentType: "text/plain; charset=utf-8",
			body: "Scheduled"
		};
	}
}

