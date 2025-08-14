package heaps.debug.server.util;

import haxe.ds.StringMap;
import haxe.io.Path;
import sys.io.File;
import EReg;

class Templating {
  public static var templatesDir:String = "src/pages";
  public static var cacheEnabled:Bool = true;
  public static var componentsDir:String = "src/components";

  static var templateCache:StringMap<String> = new StringMap<String>();
  static var componentCache:StringMap<String> = new StringMap<String>();

  public static function setTemplatesDir(dir:String):Void {
    templatesDir = dir;
  }

  public static function clearCache():Void {
    templateCache = new StringMap<String>();
    componentCache = new StringMap<String>();
  }

  public static function render(templateRelPath:String, data:Dynamic, ?layoutRelPath:String):String {
    
    final viewRaw = loadTemplateFile(templateRelPath);
    final viewWithComponents = expandComponents(viewRaw, data);
    final viewHtml = interpolate(viewWithComponents, data);
    if (layoutRelPath == null || layoutRelPath == "") {
      return viewHtml;
    }
    final layoutData:Dynamic = {};
    for (field in Reflect.fields(data)) {
      Reflect.setField(layoutData, field, Reflect.field(data, field));
    }
    Reflect.setField(layoutData, "body", viewHtml);
    final layoutRaw = loadTemplateFile(layoutRelPath);
    final layoutWithComponents = expandComponents(layoutRaw, layoutData);
    final layoutHtml = interpolate(layoutWithComponents, layoutData);
    return layoutHtml;
  }

  static function loadTemplateFile(templateRelPath:String):String {
    final normalized = normalizeTemplatePath(templateRelPath);
    if (cacheEnabled) {
      final cached = templateCache.get(normalized);
      if (cached != null) return cached;
    }
    final absPath = Path.normalize(Path.join([templatesDir, normalized]));
    final content = File.getContent(absPath);
    if (cacheEnabled) templateCache.set(normalized, content);
    return content;
  }

  static function loadComponentFile(name:String):String {
    var fileName = name;
    if (fileName.indexOf(".") == -1) fileName = fileName + ".html";
    final normalized = fileName.split("\\").join("/");
    if (cacheEnabled) {
      final cached = componentCache.get(normalized);
      if (cached != null) return cached;
    }
    final absPath = Path.normalize(Path.join([componentsDir, normalized]));
    final content = File.getContent(absPath);
    if (cacheEnabled) componentCache.set(normalized, content);
    return content;
  }

  static function normalizeTemplatePath(p:String):String {
    var out = p == null ? "" : p;
    out = out.split("\\").join("/");
    if (StringTools.startsWith(out, "/")) out = out.substr(1);
    if (out == "") return out;
    final last = out.lastIndexOf("/");
    final name = last >= 0 ? out.substr(last + 1) : out;
    if (name.indexOf(".") == -1) out = out + ".html";
    return out;
  }

  static function expandComponents(template:String, data:Dynamic):String {
    
    
    var re = new EReg("<([A-Z][A-Za-z0-9_]*)\\s*([^>/]*?)(/?)>", "g");
    var buf = new StringBuf();
    var pos = 0;
    while (re.matchSub(template, pos)) {
      final mp = re.matchedPos();
      buf.add(template.substr(pos, mp.pos - pos));
      final tagName = re.matched(1);
      final attrsRaw = re.matched(2);
      final attrs = parseAttributes(attrsRaw);
      
      for (k in attrs.keys()) {
        final v = attrs.get(k);
        final resolved = interpolate(v, data);
        attrs.set(k, resolved);
      }
      
      final merged = cloneAndMerge(data, attrs);
      
      if (tagName == "TopBar" && attrs.exists("username") == false) {
        Reflect.setField(merged, "username", "guest");
      }
      final componentSource = loadComponentFile(tagName);
      
      final expandedSource = expandComponents(componentSource, merged);
      
      final componentHtml = interpolate(expandedSource, merged);
      buf.add(componentHtml);
      pos = mp.pos + mp.len;
    }
    buf.add(template.substr(pos));
    return buf.toString();
  }

  static function parseAttributes(s:String):StringMap<String> {
    var out = new StringMap<String>();
    if (s == null) return out;
    var re = new EReg("([a-zA-Z_][a-zA-Z0-9_\\-]*)\\s*=\\s*\"([^\"]*)\"", "g");
    var pos = 0;
    while (re.matchSub(s, pos)) {
      final name = re.matched(1);
      final value = re.matched(2);
      out.set(name, value);
      final mp = re.matchedPos();
      pos = mp.pos + mp.len;
    }
    return out;
  }

  static function cloneAndMerge(base:Dynamic, attrs:StringMap<String>):Dynamic {
    var merged:Dynamic = {};
    if (base != null) {
      for (field in Reflect.fields(base)) {
        Reflect.setField(merged, field, Reflect.field(base, field));
      }
    }
    for (k in attrs.keys()) {
      Reflect.setField(merged, k, attrs.get(k));
    }
    return merged;
  }

  static function interpolate(template:String, data:Dynamic):String {
    var out = template;
    
    out = replaceAll(out, new EReg("\\{\\{\\{\\s*([a-zA-Z0-9_\\.]+)\\s*\\}\\}\\}", "g"), function(key) {
      final v = resolvePath(data, key);
      return v;
    });
    
    out = replaceAll(out, new EReg("\\{\\{\\s*([a-zA-Z0-9_\\.]+)\\s*\\}\\}", "g"), function(key) {
      final v = resolvePath(data, key);
      return escapeHtml(v);
    });
    return out;
  }

  static function replaceAll(text:String, re:EReg, replacer:String->String):String {
    var buf = new StringBuf();
    var pos = 0;
    while (re.matchSub(text, pos)) {
      final mp = re.matchedPos();
      buf.add(text.substr(pos, mp.pos - pos));
      final key = re.matched(1);
      buf.add(replacer(key));
      pos = mp.pos + mp.len;
    }
    buf.add(text.substr(pos));
    return buf.toString();
  }

  static function resolvePath(data:Dynamic, path:String):String {
    var current:Dynamic = data;
    final parts = path.split(".");
    for (p in parts) {
      if (current == null) return "";
      current = Reflect.field(current, p);
    }
    if (current == null) return "";
    return Std.string(current);
  }

  public static function escapeHtml(s:String):String {
    if (s == null) return "";
    var out = s;
    out = StringTools.replace(out, "&", "&amp;");
    out = StringTools.replace(out, "<", "&lt;");
    out = StringTools.replace(out, ">", "&gt;");
    out = StringTools.replace(out, '"', "&quot;");
    out = StringTools.replace(out, "'", "&#39;");
    return out;
  }
} 