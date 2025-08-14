# heaps-debug-server

```
class TestServeApp extends hxd.App {

    override function init() {
        super.init();
        HeapsDebugServer.attach(this, 8080); // host an http server inside a heaps game at port 8080
        s2d.addChild(new h2d.Bitmap(h2d.Tile.fromColor(0xE40000, 100, 100)));
    }

    public static function main() {
        new TestServeApp();
    }
}
```
Then access the debug dashboard at `http://localhost:8080/dashboard`

<img width="1307" height="892" alt="heaps_debug" src="https://github.com/user-attachments/assets/02d00a01-4771-46f6-93d5-a73344df9b30" />
