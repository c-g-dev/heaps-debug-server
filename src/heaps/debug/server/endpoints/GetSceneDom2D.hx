package heaps.debug.server.endpoints;

import heaps.debug.HeapsDebugServer;
import heaps.debug.HeapsDebugServer.IHeapsDebugEndpoint;
import heaps.debug.HeapsDebugServer.HeapsDebugRequest;
import heaps.debug.HeapsDebugServer.HeapsDebugResponse;
import heaps.debug.HeapsDebugServer.SceneObjectRegistry;
import hxd.App;
import h2d.Object;
import haxe.Json;

class GetSceneDom2D implements IHeapsDebugEndpoint {
    public var method(default, null): String = "GET";
    public var path(default, null): String = "/scene/dom2d";

    public static function register(): Void {
        HeapsDebugServer.registerEndpoint(new GetSceneDom2D());
    }

    public function new() {}

    public function handle(server: HeapsDebugServer, req: HeapsDebugRequest): HeapsDebugResponse {

		
        var snapshotRegistry = getRegistry();
        HeapsDebugServer.setLastScene2DRegistry(snapshotRegistry.registry); 
        var json = Json.stringify(snapshotRegistry.snapshot, null, "  ");
        return {
            status: 200,
            contentType: "application/json; charset=utf-8",
            body: json
        };
    }

    public static function getRegistry(): {snapshot:Dynamic, registry:SceneObjectRegistry} {

        var app = HeapsDebugServer.getApp();
        var registry: SceneObjectRegistry = {
            idToObject: new Map(),
            objectToId: new Map()
        };

        var nextId = 1;
        function getOrAssignId(obj:Object): String {
            if (registry.objectToId.exists(obj)) return registry.objectToId.get(obj);
            var id = "o" + nextId;
            nextId++;
            registry.objectToId.set(obj, id);
            registry.idToObject.set(id, obj);
            return id;
        }

        function serialize(o:Object): Dynamic {
            var out: Dynamic = {
                id: getOrAssignId(o),
                type: Type.getClassName(Type.getClass(o)),
                x: o.x,
                y: o.y,
                sx: o.scaleX,
                sy: o.scaleY,
                alpha: o.alpha,
                visible: o.visible,
                children: []
            };
            var count = o.numChildren;
            var children = (out:Dynamic).children;
            var i = 0;
            while (i < count) {
                var c = o.getChildAt(i);
                children.push(serialize(c));
                i++;
            }
            return out;
        }

        var snapshot = serialize(app.s2d);
        return {snapshot: snapshot, registry: registry};
    }

    
    static function serializeObject(obj: Object): Dynamic {
        return null;
    }
}

