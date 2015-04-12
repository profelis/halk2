package halk;

import haxe.io.Bytes;
import hscript.Printer;
import halk.Macro.MacroContext;
import haxe.Serializer;
import haxe.Unserializer;
import hscript.Expr;

#if macro
import sys.FileSystem;
import sys.io.File;

import haxe.io.Path;

import haxe.macro.Compiler;
import haxe.macro.Context;
import halk.macro.LiveProcessor;
import haxe.macro.Expr.Field;

using haxe.macro.Tools;
#end

using StringTools;

class MacroContext {

    static public inline var LIVE_FILE_NAME = "data.live";

    public function new() {}

    public var version:Int = 0;

    public var methods:Map<String, Expr> = new Map();
    public var types:Map<String, Array<String>> = new Map();

    public inline function toFile():String {
        Serializer.USE_ENUM_INDEX = true;

        return '$version\n' + Serializer.run(this);
    }

    public static function getVersion(fileCont:String):Int {
        if (fileCont == null) return 0;
        var lines = fileCont.split("\n");
        var res = Std.parseInt(lines[0]);
        return res == null ? 0 : res;
    }

    public static function fromFile(fileCont:String):MacroContext {
        if (fileCont == null) return null;
        var lines = fileCont.split("\n");
        if (lines.length < 2) return null;
        return try {
            Unserializer.run(lines[1]);
        } catch (e:Dynamic) { null; }
    }
}

class Macro {

    #if macro
    static var processor = new LiveProcessor();

    static var liveContext = new LiveProcessorContext();

    static inline function reset() {
        liveContext = new LiveProcessorContext();
    }

    // todo: refactor this shit
    static function getOutPath() {

        var isLime = Context.defined("lime") || Context.defined("nme") || Context.defined("openfl");

        var path = Compiler.getOutput();
        if (FileSystem.exists(path))
            path = FileSystem.fullPath(path);

        var p = new Path(path);
        if (FileSystem.exists(path)) {
            if (!FileSystem.isDirectory(path)) {
                p = new Path(p.dir); // swf, n file
            }
        }
        else if (Context.defined("flash") || Context.defined("neko") || Context.defined("js")) {
            p = new Path(p.dir); // swf, n, js file
        }

        // lime obj folder
        if (isLime && p.file == "obj") {
            p = new Path(p.dir + "/bin");
            trace(p);
        }

        if (Context.defined("mac")) {
            var main = null;
            for (f in FileSystem.readDirectory(p.toString())) {
                if (StringTools.endsWith(f, ".app")) {
                    main = f;
                    break;
                }
            }
            if (main != null) {
                if (isLime) {
                    p = new Path(p.toString() + "/" + main + "/Contents/Resources");
                } else {
                    p = new Path(p.toString() + "/" + main + "/Contents/MacOS");
                }
                trace(p);
            }
        }

        return p.toString() + "/" + MacroContext.LIVE_FILE_NAME;
    }

    static function onGenerate(types:Array<haxe.macro.Type>) {
        Compiler.keep('Type');
        Compiler.keep('haxe.Log');

        var context = new MacroContext();
        processor.postProcess(types, liveContext, context);

        var path = getOutPath();
        try {
            // todo: global version
            var cont = File.getContent(path);
            context.version = MacroContext.getVersion(cont) + 1;
        } catch (e:Dynamic) {
            // todo: Warn.error
            trace(e);
        }

        trace("Config saved: " + path);
        var cont = context.toFile();
        File.saveContent(path, cont);
        Context.addResource(MacroContext.LIVE_FILE_NAME, Bytes.ofString(cont));
        reset();
    }

    static function onMacroContextReused() {
        reset();
        return true;
    }

    #end

    macro static public function build():Array<Field> {

        Context.onMacroContextReused(onMacroContextReused);
        Context.onGenerate(onGenerate);

        var classType = Context.getLocalType().getClass();

        if (liveContext.isRegistered(classType)) return null;

        var fields = Context.getBuildFields();
        return processor.process(classType, fields, liveContext);
    }
}