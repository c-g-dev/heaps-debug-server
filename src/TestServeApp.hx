import heaps.debug.HeapsDebugServer;

class TestServeApp extends hxd.App {

    override function init() {
        super.init();
        HeapsDebugServer.attach(this, 8080);
        s2d.addChild(new h2d.Bitmap(h2d.Tile.fromColor(0xE40000, 100, 100)));
    }

    public static function main() {
        new TestServeApp();
    }
}