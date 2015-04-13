package halk.macro;


import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import hscript.Expr.Argument;
import halk.Macro.MacroContext;
import halk.macro.TypeTools.BaseTypeTools;

using halk.macro.MetaTools;
using haxe.macro.Tools;
using hscript.Printer;
using halk.MapTools;

typedef MethodData = {
    expr:Expr,
    args:Array<FunctionArg>
}

typedef ClassData = {
    name:String,
    fields:Array<String>
}

class LiveProcessorContext {

    var classes:Map<String, ClassData> = new Map();

    public function new() {}

    public inline function isRegistered(type:ClassType) {
        return classes.exists(key(type));
    }

    public inline function findClassData(type:haxe.macro.Type):Null<ClassData> {
        return if (type == null) null;
        else switch type {
                case TInst(t, _): classes.get(key(t.get()));
                case _: null;
            }
    }

    public inline function register(type:ClassType, data:ClassData) {
        data.name = key(type);
        classes[data.name] = data;
    }

    inline function key(type:ClassType):String return BaseTypeTools.baseTypePath(type).join(".");

}

// TODO: super support (fake callSuper$MethodName$ function)
// TODO: live ctor
class LiveProcessor {

    static inline var LIVE_META = "live";
    static inline var NO_LIVE_META = "noLive";
    static inline var LIVE_UPDATE_META = "liveUpdate";

    public function new() {}

    var additionalFields:Array<Field>;
    var ctorPatch:Array<Expr>;
    var destructor:Array<Expr>;

    var classData:ClassData;

    var scriptConverter:HScriptTypedConverter = new HScriptTypedConverter();
    var macroContext:MacroContext;

    public function process(classType:ClassType, fields:Array<Field>, liveContext:LiveProcessorContext):Array<Field> {
        classData = { fields:[], name:null };
        liveContext.register(classType, classData);
        additionalFields = [];
        ctorPatch = [];
        destructor = [];

        var classLiveMeta = classType.meta.get().findMeta(LIVE_META);
        var liveAllClass = classLiveMeta != null;

        for (f in fields) {
            var blockLive = f.meta.findMeta(NO_LIVE_META) != null;
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
            if (liveAllClass && liveMeta == null) liveMeta = classLiveMeta;

            if (liveUpdateMeta != null) {
                processLiveUpdateField(classType, f, liveUpdateMeta, blockLive ? null : liveMeta);
            }
            else if (!blockLive && liveMeta != null) {
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
                case _:
            }

            var destType = macro class T {
                public function removeAllLiveListeners() $b{destructor};
            }
            additionalFields.push(destType.fields[0]);
        }

        return fields.concat(additionalFields);
    }

    public function postProcess(types:Array<haxe.macro.Type>, liveContext:LiveProcessorContext, macroContext:MacroContext):Void {
        for (t in types) {
            var classData:ClassData = liveContext.findClassData(t);
            if (classData == null) continue;

            var classType:ClassType = t.getClass();

            for (f in classType.fields.get()) {
                if (classData.fields.indexOf(f.name) == -1) continue;
                var expr:TypedExpr;
                var args:Array<{v:TVar, value:Null<TConstant>}>;
                switch (f.expr().expr) {
                    // function { return #magic#, {#old_function_body#} }
                    case TFunction({args:a, expr:{expr:TBlock([{expr:TReturn(_)}, e])}}):
                        expr = e;
                        args = a;
                    case _: throw false;
                };

                var convertData = scriptConverter.convert(classType, expr);

                var fArg:Array<Argument> = [for (arg in args) {name:arg.v.name, opt:arg.value != null}];
                macroContext.methods.set(classData.name + "." + f.name, hscript.Expr.EFunction(fArg, convertData.e));
                macroContext.types.add(convertData.types);
            }
        }
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
        var typeName = BaseTypeTools.baseTypePath(type).join(".") + ".";

        switch field.kind {
            case FFun(f):
                classData.fields.push(field.name);

                var exprs = [f.expr];
                var args = [for (arg in f.args) macro $i{arg.name}];
                exprs.unshift(macro return halk.Live.instance.call(this, $v{typeName + field.name}, $a{args}));

                f.expr = macro $b{exprs};
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
