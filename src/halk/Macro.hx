package halk;

import haxe.io.Bytes;
import haxe.Serializer;
import haxe.Unserializer;
import hscript.Expr;
import halk.Macro.MacroContext;

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

    static function parseCont(fileCont:String, unserialize:Bool):{version:Int, data:Dynamic} {
        if (fileCont == null) return null;
        var lines = fileCont.split("\n");
        if (lines.length < 2) return null;

        var data:Dynamic = if (unserialize) {
            try {
                Unserializer.run(lines[1]);
            } catch (e:Dynamic) { null; }
        } else {
            lines[1];
        }
        return {version:Std.parseInt(lines[0]), data:data};
    }

    public static function getVersion(fileCont:String):Int {
        var data = parseCont(fileCont, false);
        return if (data == null) 0; else data.version;
    }

    public static function fromFile(fileCont:String):MacroContext {
        var data = parseCont(fileCont, true);
        return if (data == null) null; else data.data;
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

        var cont = context.toFile();
        File.saveContent(path, cont);
        neko.Lib.println("Config saved: " + path);
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