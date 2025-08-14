package heaps.debug.util;

import heaps.debug.HeapsDebugServer;
import h2d.Graphics;
import h2d.Object;
import h2d.col.Bounds;

class Highlighter extends h2d.Object {
	static var instance: Highlighter;

	var target: Object;
	var gfx: Graphics;
	var bounds: Bounds;

	public function new() {
		super();
		gfx = new Graphics(this);
		bounds = new Bounds();
	}

	public static function highlight(obj: Object): Void {
		ensureInstalled();
		instance.target = obj;
		instance.visible = true;
		instance.redraw();
	}

	public static function clear(): Void {
		if (instance == null) return;
		instance.target = null;
		instance.gfx.clear();
		instance.visible = false;
	}

	static function ensureInstalled(): Void {
		if (instance != null) return;
		var app = HeapsDebugServer.getApp();
		instance = new Highlighter();
		app.s2d.addChild(instance);
	}

	override function sync(ctx: h2d.RenderContext) {
		super.sync(ctx);
		if (target == null) return;
		redraw();
	}

	function redraw(): Void {
		if (target == null) return;
		var app = HeapsDebugServer.getApp();
		
		if(target == this.getScene()) {
			bounds = Bounds.fromValues(0, 0, (cast target:h2d.Scene).width, (cast target:h2d.Scene).height);
		} else {
			bounds = target.getBounds();
		}
		gfx.clear();
		
		var x = bounds.xMin;
		var y = bounds.yMin;
		var w = bounds.width;
		var h = bounds.height;
		
		this.x = 0;
		this.y = 0;
		gfx.lineStyle(2, 0x33FF66, 1.0);
		gfx.drawRect(x, y, w, h);
	}
}


