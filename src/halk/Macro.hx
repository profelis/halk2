package halk;

import haxe.Serializer;
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

    public var id:Int = 0;

    public var methods:Map<String, Expr> = new Map();
    public var types:Map<String, Array<String>> = new Map();
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
            trace(context);
            Serializer.USE_ENUM_INDEX = true;

            var path = getOutPath();
            try {
                var cont = File.getContent(path);
                context.id = Std.parseInt(cont.split("\n")[0]) + 1;
            } catch (e:Dynamic) {
                trace(e);
            }
            var data = Serializer.run(context);
            File.saveContent(path, context.id + "\n" + data);
            reset();
        });

        var type = Context.getLocalType();

        var fields = Context.getBuildFields();

        return processor.process(type, fields, context, processed);
    }
}