package heaps.debug.browser;

class UpdateObjectField {
    
    public static function run(objectId:String, fieldName:String, value:Dynamic):Void {
        var code = buildScript(objectId, fieldName, value);
        sendEval(code);
    }

    static function buildScript(objectId:String, fieldName:String, value:Dynamic):String {
        var valueExpr = toHScriptLiteral(value);
        var sb = new StringBuf();
        sb.add("var o = get2d(\""); sb.add(objectId); sb.add("\");\n");
        sb.add("o."); sb.add(fieldName); sb.add(" = "); sb.add(valueExpr); sb.add(";\n");
        return sb.toString();
    }

    static function toHScriptLiteral(v:Dynamic):String {
        return switch (Type.typeof(v)) {
            case TBool: v ? "true" : "false";
            case TInt, TFloat: Std.string(v);
            case TNull: "null";
            case TClass(String): quoteString(Std.string(v));
            default: quoteString(haxe.Json.stringify(v));
        };
    }

    static inline function quoteString(s:String):String {
        var out = new StringBuf();
        out.add("\"");
        var i = 0;
        while (i < s.length) {
            var c = s.charCodeAt(i);
            switch (c) {
                case 34: out.add("\\\""); 
                case 92: out.add("\\\\"); 
                case 10: out.add("\\n");
                case 13: out.add("\\r");
                case 9: out.add("\\t");
                default: out.add(String.fromCharCode(c));
            }
            i++;
        }
        out.add("\"");
        return out.toString();
    }

    static function sendEval(code:String):Void {
        #if js
        js.Syntax.code(
            "fetch('/eval', { method: 'POST', headers: { 'Content-Type': 'text/plain' }, body: {0} })",
            code
        );
        #else
        
        #end
    }
}


