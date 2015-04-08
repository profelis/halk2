package halk.macro;

import hscript.Printer;
import haxe.macro.Type.ClassType;
import haxe.macro.Expr;
import hscript.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;

typedef HExpr = hscript.Expr;

abstract ExtExpr(Array<HExpr>) from Array<HExpr> to Array<HExpr> {

    public inline function new(exprs:Array<HExpr>) {
        this = exprs;
    }

    public inline inline function all():Array<HExpr> return this;

    @:from static inline function fromExpr(value:HExpr) {
        return new ExtExpr([value]);
    }

    @:to inline function toExpr():HExpr {
        if (this != null && this.length > 1) {
            throw "exprs num > 1";
        }
        return this == null ? null : this[0];
    }
}

class HScriptConverter {

    var binops:Map<Binop, String>;
    var unops:Map<Unop, String>;

    var printer = new Printer();

    var types:Map<String, Array<String>>;

    public function new() {

        binops = new Map();
        unops = new Map();
        for( c in Type.getEnumConstructs(Binop) ) {
            if( c == "OpAssignOp" ) continue;
            var op = Type.createEnum(Binop, c);
            var assign = false;
            var str = switch( op ) {
                case OpAdd: assign = true;  "+";
                case OpMult: assign = true; "*";
                case OpDiv: assign = true; "/";
                case OpSub: assign = true; "-";
                case OpAssign: "=";
                case OpEq: "==";
                case OpNotEq: "!=";
                case OpGt: ">";
                case OpGte: ">=";
                case OpLt: "<";
                case OpLte: "<=";
                case OpAnd: assign = true; "&";
                case OpOr: assign = true; "|";
                case OpXor: assign = true; "^";
                case OpBoolAnd: "&&";
                case OpBoolOr: "||";
                case OpShl: assign = true; "<<";
                case OpShr: assign = true; ">>";
                case OpUShr: assign = true; ">>>";
                case OpMod: assign = true; "%";
                case OpAssignOp(_): "";
                case OpInterval: "...";
                case OpArrow: "=>";
            };
            binops.set(op, str);
            if( assign )
                binops.set(OpAssignOp(op), str + "=");
        }
        for( c in Type.getEnumConstructs(Unop) ) {
            var op = Type.createEnum(Unop, c);
            var str = switch( op ) {
                case OpNot: "!";
                case OpNeg: "-";
                case OpNegBits: "~";
                case OpIncrement: "++";
                case OpDecrement: "--";
            }
            unops.set(op, str);
        }
    }

    public function convert(type:ClassType, expr:haxe.macro.Expr):{e:HExpr, types:Map<String, Array<String>>} {
        types = new Map();
        var e:HExpr = map(expr);
        trace(e);
        return {e:e, types:types};
    }

    function map(e:haxe.macro.Expr):ExtExpr {
        if (e == null) return null;

        inline function mapArray(arr:Array<haxe.macro.Expr>):Array<HExpr> {
            return [for (p in arr) map(p)];
        }

        inline function registerType(e:haxe.macro.Expr) {
            try {
                convertType(Context.typeof(e).toComplexType(), e.pos);
            } catch (e:Dynamic) {
                trace(e);
            }
        }

        return switch e.expr {
            case EConst(CInt(c)): EConst(Const.CInt(Std.parseInt(c)));
            case EConst(CFloat(c)): EConst(Const.CFloat(Std.parseFloat(c)));
            case EConst(CString(c)): EConst(Const.CString(c));
            case EConst(CIdent(c)): registerType(e); EIdent(c);
            case EConst(CRegexp(r, opt)): ENew("EReg", [EConst(Const.CString(r)), EConst(Const.CString(opt))]);
            case EArray(e1, e2): EArray(map(e1), map(e2));
            case EBinop(OpAssignOp(op), e1, e2): EBinop(binops.get(op) + "=", map(e1), map(e2));
            case EBinop(op, e1, e2): EBinop(binops.get(op), map(e1), map(e2));
            case EField(e, field): registerType(e); EField(map(e), field);

            case EParenthesis(e): EParent(map(e));
            case EObjectDecl(fields): EObject([for (f in fields) {name:f.field, e:map(f.expr)}]);
            case EArrayDecl(el): EArrayDecl(mapArray(el));
            case ECall(e, params): registerType(e); ECall(map(e), mapArray(params));
            case ENew(tp, params): ENew(cTypeToString(convertTypePath(tp, e.pos)), mapArray(params));
            case EUnop(op, postFix, e): EUnop(unops.get(op), postFix, map(e));
            case EVars(vars):
                var res = [];
                for (v in vars) {
                    res.push(EVar(v.name, convertType(v.type, e.pos), map(v.expr)));
                }
                res;

            case EBlock(el):
                var res = [];
                for (e in el) {
                    var items = map(e);
                    if (items != null) {
                        for (t in items.all()) {
                            res.push(t);
                        }
                    } else {
                        res.push(null);
                    }
                }
                EBlock(res);

            case EFor(it, expr):
                var v:String;
                var resIt;
                switch it.expr {
                    case EIn(a, b):
                        v = printer.exprToString(map(a));
                        resIt = map(b);
                    case _:
                        Context.error("this kind of for loops are not implemented", e.pos);
                }
                EFor(v, resIt, map(expr));

            case EIn(e1, e2): Context.error("in operator not implemented. for-in only supported", e.pos); //EIn(map(e1), map(e2));
            case EIf(econd, eif, eelse): EIf(map(econd), map(eif), map(eelse));
            case EWhile(econd, e, true): EWhile(map(econd), map(e));
            case EWhile(econd, e, false): Context.error("do{}while() not implemented", econd.pos); //EWhile(f(econd), map(e), normalWhile);
            case EReturn(e): EReturn(map(e));
            case EUntyped(e): map(e);
            case EThrow(e): EThrow(map(e));
            case ECast(e, t): convertType(t, e.pos); map(e);
            case EDisplay(e, isCall): map(e); //EDisplay(f(e), isCall);
            case ETernary(econd, eif, eelse): ETernary(map(econd), map(eif), map(eelse));
            case ECheckType(e, t): convertType(t, e.pos); map(e); //ECheckType(map(e), t); // (a:TypeName)
            case EDisplayNew(tp): EBlock([]); // autocompletion ??
            case EContinue: EContinue;
            case EBreak: EBreak;
            case ETry(etry, catches):
                if (catches.length > 1) {
                    Context.warning("halk support only first catch", e.pos);
                }
                var c = catches[0];
                ETry(map(etry), c.name, convertType(c.type, e.pos), map(c.expr));

            case ESwitch(e, cases, edef):
                var res:Array<{values:Array<HExpr>, expr:HExpr}> = [];
                for (c in cases) {
                    if (c.guard != null) {
                        Context.warning("halk does'n support guards", e.pos);
                    }
                    res.push({expr:map(c.expr), values:mapArray(c.values)});
                }
                ESwitch(map(e), res, map(edef));

            case EFunction(name, func):
                var args = [];
                for (arg in func.args) {
                    if (arg.value != null) {
                        Context.warning("default args not implemented", e.pos);
                    }
                    args.push({name:arg.name, opt:arg.opt, t:convertType(arg.type, e.pos) } );
                }
                EFunction(args, map(func.expr), name, convertType(func.ret, e.pos));

            case EMeta(m, e): map(e); //EMeta(m, map(e));
        };
    }

    function cTypeToString(type:CType):String @:privateAccess {
        printer.buf = new StringBuf();
        printer.tabs = "";
        printer.type(type);
        return printer.buf.toString();
    }

    function convertTypePath(p:TypePath, pos:Position):CType {
        var path = p.pack.length > 0 ? p.pack.concat([p.name]) : [p.name];
        var type = Context.getType(path.join("."));
        var fullPath = TypeTools.getFullPath(type);
        if (fullPath != null) {
            if (fullPath[0] == "StdTypes") {
                fullPath.shift();
            }
            path = fullPath;
        }

        types.set(path.join("."), path);
        return CTPath(path, null);
    }

    function convertType(type:ComplexType, pos:Position):CType {
        if (type == null) return null;

        return switch type {
            case TPath(p):
                convertTypePath(p, pos);
            case TFunction(args, ret): CTFun([for (a in args) convertType(a, pos)], convertType(ret, pos));
            case TExtend(_, fields) | TAnonymous(fields):
                var res = [];
                for (f in fields) {
                    var name = f.name;
                    switch f.kind {
                        case FVar(t, e):
                            if (e != null) Context.error('default values are not supported in anonymous structs', pos);
                            res.push({name: name, t: convertType(t, pos)});

                        case FProp(_, _):
                            Context.error('properties are not supported in anonymous structs', pos);

                        case FFun(f):
                            var type = CTFun([for (a in f.args) convertType(a.type, pos)], convertType(f.ret, pos));
                            res.push({name: name, t: type});
                    }
                }
                CTAnon(res);
            case TParent(t): CTParent(convertType(t, pos));
            //case TExtend(p, fields): throw "not implemented"; // TODO: FIX: case TExtend(_, fields) | TAnonymous(fields):
            case TOptional(t): convertType(t, pos);
        }
    }
}
