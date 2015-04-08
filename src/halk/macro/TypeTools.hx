package halk.macro;

import haxe.macro.Type.BaseType;

using StringTools;

class TypeTools {

    static public inline function baseTypePath(t:BaseType):Array<String> {
        return if (t == null) {
            null;
        } else if (t.module.endsWith(t.name)) {
            t.module.split(".");
        } else {
            t.module.length > 0 ? t.module.split(".").concat([t.name]) : [t.name];
        }
    }

    static public function getFullPath(type:haxe.macro.Type):Array<String> {
        if (type == null) return null;

        return switch type {
            case TMono(tp): getFullPath(tp.get());
            case TEnum(tp, _): baseTypePath(tp.get());
            case TInst(tp, _): baseTypePath(tp.get());
            case TType(tp, _): baseTypePath(tp.get());
            case TFun(_, _): null;
            case TAnonymous(_): null;
            case TDynamic(_): null;
            case TLazy(f): getFullPath(f());
            case TAbstract(tp, _): baseTypePath(tp.get());
        }
    }
}
