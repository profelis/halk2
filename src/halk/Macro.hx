package halk;

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
#end

using StringTools;

class MacroContext {
    public function new() {}

    public var version:Int = 0;

    public var methods:Map<String, Expr> = new Map();
    public var types:Map<String, Array<String>> = new Map();

    public function toFile():String {
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

    static var processed:Array<String> = [];
    static var context = new MacroContext();

    static function reset() {
        processed = [];
        context = new MacroContext();
    }

    static function getOutPath() {
        var path = FileSystem.fullPath(Compiler.getOutput());
        var p = new Path(path);
        if (!FileSystem.isDirectory(path)) p = new Path(p.dir); // swf, n file
        trace(p);

        #if sys // lime obj folder
        if (p.file == "obj") p = new Path(p.dir + "/bin");
        trace(p);
        #end

        #if mac
        var main = null;
        for (f in FileSystem.readDirectory(p.toString())) {
            if (StringTools.endsWith(f, ".app")) {
                main = f;
                break;
            }
        }
        if (main != null) {
            #if lime
            p = new Path(p.toString() + "/" + main + "/Contents/Resources");
            #else
            p = new Path(p.toString() + "/" + main + "/Contents/MacOS");
            #end
            trace(p);
        }
        #end

        return p.toString() + "/data.live";
    }

    #end

    macro static public function build():Array<Field> {

        Context.onMacroContextReused(function () {
            reset();
            return true;
        });

        Context.onAfterGenerate(function () {
            var path = getOutPath();
            try {
                var cont = File.getContent(path);
                context.version = MacroContext.getVersion(cont) + 1;
            } catch (e:Dynamic) {
                trace(e);
            }

            File.saveContent(path, context.toFile());
            reset();
        });

        var type = Context.getLocalType();

        var fields = Context.getBuildFields();

        return processor.process(type, fields, context, processed);
    }
}