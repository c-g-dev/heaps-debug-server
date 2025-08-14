package heaps.debug.util;

class RunOnUIThread extends h2d.Object {

    var cb: Void->Void;

    public function new(cb: Void->Void) {
        this.cb = cb;
        super();
    }

    public override function sync(ctx: h2d.RenderContext) {
        super.sync(ctx);
        cb();
        this.remove();
    }
}