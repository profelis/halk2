package halk.macro;


import haxe.macro.Context;
import haxe.macro.Type.ClassType;
import halk.Macro.MacroContext;
import haxe.macro.Expr;

using halk.macro.MetaTools;
using haxe.macro.Tools;
using hscript.Printer;
using halk.MapTools;


class LiveProcessor {

    static inline var LIVE_META = "live";
    static inline var LIVE_UPDATE_META = "liveUpdate";

    public function new() {}

    var additionalFields:Array<Field>;
    var ctorPatch:Array<Expr>;
    var destructor:Array<Expr>;
    var macroContext:MacroContext;

    var scriptConverter = new HScriptConverter();

    public function process(type:haxe.macro.Type, fields:Array<Field>, macroContext:MacroContext, processed:Array<String>):Array<Field> {

        this.macroContext = macroContext;
        additionalFields = [];
        ctorPatch = [];
        destructor = [];

        var classType = type.getClass();
        var typeName = type.toString();
        if (processed.indexOf(typeName) > -1) {
            return fields;
        }
        processed.push(typeName);

        for (f in fields) {
            var liveMeta = f.meta.findMeta(LIVE_META);
            var liveUpdateMeta = f.meta.findMeta(LIVE_UPDATE_META);

            if (ignoreField(f)) {
                if (liveMeta != null) {
                    Context.warning('"${LIVE_META}" meta ignored', f.pos);
                }
                if (liveUpdateMeta != null) {
                    Context.warning('${LIVE_UPDATE_META} meta ignored', f.pos);
                }
                continue;
            }

            if (liveUpdateMeta != null) {
                processLiveUpdateField(classType, f, liveUpdateMeta, liveMeta);
            }
            else if (liveMeta != null) {
                processLiveField(classType, f, liveMeta);
            }
        }

        if (ctorPatch.length > 0) {
            var ctor:Field = null;
            for (f in fields) {
                if (f.name == "new") {
                    ctor = f;
                    break;
                }
            }
            if (ctor == null) {
                Context.error("ctor expected", fields[0].pos);
            }

            switch (ctor.kind) {
                case FFun(f):
                    f.expr = macro {
                        ${f.expr};
                        $b{ctorPatch}
                    };

                    trace(f.expr.toString());
                case _:
            }
        }

        return fields.concat(additionalFields);
    }

    function processLiveUpdateField(type:ClassType, field:Field, meta:MetadataEntry, liveMeta:MetadataEntry):Void {
        switch field.kind {
            case FFun(f):
            if (f.args.length > 0) {
                Context.error("${LIVE_UPDATE_META} functions doesn't support args", field.pos);
            }
            var fn = field.name;
            ctorPatch.push(macro halk.Live.instance.addListener(this.$fn));
            destructor.push(macro halk.Live.instance.removeListener(this.$fn));
            case _:
        }

        if (liveMeta != null) {
            processLiveField(type, field, liveMeta);
        }
    }

    function processLiveField(type:ClassType, field:Field, meta:MetadataEntry):Void {
        switch field.kind {
            case FFun(f):
                //trace(f);
                var args = [for (arg in f.args) macro $i{arg.name}];
                var expr = f.expr;
                var convertData = scriptConverter.convert(type, expr);

                var type = TypeTools.baseTypePath(type);
                var mn = type.join(".") + "." + field.name;

                macroContext.types.add(convertData.types);
                macroContext.methods.set(mn, hscript.Expr.EFunction([for (arg in f.args) {name:arg.name, opt:arg.opt}], convertData.e));

                var exprs = [];

                exprs.push(macro return halk.Live.instance.call(this, $v{mn}, $a{args}));
                exprs.push(expr);

                f.expr = macro $b{exprs};
                trace(f.expr.toString());
            case _:
        }
    }

    function ignoreField(field:Field):Bool {
        if (field.name == "new") {
            return true;
        }

        switch field.kind {
            case FVar(_) | FProp(_, _): return true;
            case _:
        }

        for (access in field.access) {
            switch access {
                case AStatic | AMacro:
                    return true;
                case _:
            }
        }

        return false;
    }
}
