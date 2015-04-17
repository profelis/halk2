package halk.macro;

#if macro

import halk.macro.TypeTools;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class SuperReplacer {

    public inline function replaceName(field:String):String {
        return prefix + field;
    }

    var prefix = "super_";

    var added:Map<String, Bool>;

    public function new() {}

    public function generateSupers(type:ClassType):Array<Field> {
        var res = [];
        added = new Map<String, Bool>();
        generate(type, res);
//        for (f in res) {
//            trace(f.name);
//            trace(f.kind);
//        }
        return res;
    }

    inline function constToexpr(c:TConstant):Expr {
        return switch c {
            case TInt(i): macro $v{i};
            case TFloat(s): macro $v{Std.parseFloat(s)};
            case TString(s): macro $v{s};
            case TBool(b): macro $v{b};
            case TNull: macro null;
            case TThis: macro this;
            case TSuper: macro super;
        }
    }

    function generate(type:ClassType, res:Array<Field>) {


        for (f in type.fields.get()) {

            inline function add(name:String, fielfType:FieldType) {
                if (added.exists(name)) return;
                added[name] = true;
                res.push({
                    name : name,
                    doc : null,
                    access : [APrivate],
                    kind : fielfType,
                    pos : f.pos
                    //meta : null
                });
            };

            inline function addFn(name:String, fn:Function) {
                add(name, FFun(fn));
            }

            var name = f.name;
            var type = TypeTools.toComplexType(f.type);

            switch f.kind {
                case FMethod(kind) if (kind != MethMacro):
                    switch f.expr().expr {
                        case TFunction(fn):
                            var args = [for (a in fn.args) {
                                name : a.v.name,
                                opt : a.value != null,
                                type : TypeTools.toComplexType(a.v.t),
                                value : a.value == null ? null : constToexpr(a.value)
                            }];
                            var params = [for (a in fn.args) macro $i{a.v.name}];
                            addFn(replaceName(f.name), {
                                args: args,
                                ret : null,
                                expr : macro return super.$name($a{params})
                            });
                        case _:
                    }

                case FMethod(_):

                case FVar(read, write):
//                //FProp( get : String, set : String, ?t : Null<ComplexType>, ?e : Null<Expr> );
//                    var fr = "never";
//                    var fw = "never";
//                    switch read {
//                        case AccCall:
//                            fr = "get_" + replaceName(f.name);
//                            addFn(fr, {
//                                args: [],
//                                ret : type,
//                                expr : macro return super.$name
//                            });
//                        case _:
//                    }
//
//                    switch write {
//                        case AccCall:
//                        fw = "set_" + replaceName(f.name);
//                            addFn(fw, {
//                                args: [{name:"value", type:type}],
//                                ret : type,
//                                expr : macro return super.$name = value
//                            });
//                        case _:
//                    }
//
//                if (fr != "never" || fw != "never")
//                    add(replaceName(f.name), FProp(fr, fw, type, null));
            }
        }

        var parent = type.superClass;
        if (parent != null)
            generate(parent.t.get(), res);
    }
}
#end
