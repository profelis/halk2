package halk.macro;

import haxe.macro.Expr.ComplexType;
import haxe.macro.Type.BaseType;

using StringTools;

class TypeTools {

    static public inline function getFullPath(type:haxe.macro.Type):Array<String> {
        return if (type == null) null;
        else switch type {
            case TMono(tp): getFullPath(tp.get());
            case TEnum(tp, _): BaseTypeTools.baseTypePath(tp.get());
            case TInst(tp, _): BaseTypeTools.baseTypePath(tp.get());
            case TType(tp, _): BaseTypeTools.baseTypePath(tp.get());
            case TFun(_, _): null;
            case TAnonymous(_): null;
            case TDynamic(_): null;
            case TLazy(f): getFullPath(f());
            case TAbstract(tp, _): BaseTypeTools.baseTypePath(tp.get());
        }
    }

    static public inline function toComplexType(type:haxe.macro.Type):ComplexType {
        return haxe.macro.TypeTools.toComplexType(type);
    }
}


class BaseTypeTools {

    static public inline function baseTypePath(t:BaseType):Array<String> {
        return if (t == null) {
            null;
        } else if (t.module.endsWith(t.name)) {
            t.module.split(".");
        } else {
            t.module.length > 0 ? t.module.split(".").concat([t.name]) : [t.name];
        }
    }
}
