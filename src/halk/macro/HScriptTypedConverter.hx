package halk.macro;

#if macro

import halk.macro.TypeTools;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import hscript.Expr;
import halk.macro.TypeTools;

using hscript.Printer;
using haxe.macro.Tools;

using StringTools;

class HScriptTypedConverter {

    var binops:Map<Binop, String>;
    var unops:Map<Unop, String>;

    var types:Map<String, Array<String>>;

    static var breakedId:Int = 0;

    var superReplacer:SuperReplacer;

    public function new() {

        binops = new Map();
        unops = new Map();
        for( c in std.Type.getEnumConstructs(Binop) ) {
            if( c == "OpAssignOp" ) continue;
            var op = std.Type.createEnum(Binop, c);
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
                case OpIn: "in";
            };
            binops.set(op, str);
            if( assign )
                binops.set(OpAssignOp(op), str + "=");
        }
        for( c in std.Type.getEnumConstructs(Unop) ) {
            var op = std.Type.createEnum(Unop, c);
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

    public function convert(type:ClassType, expr:TypedExpr, superReplacer:SuperReplacer):{e:hscript.Expr, types:Map<String, Array<String>>} {
        this.superReplacer = superReplacer;
        types = new Map();
//        trace(expr);
//        trace(expr.toString());
        var e:hscript.Expr = map(expr);
//        trace(e.toString());
//        trace(e);
        return {e:e, types:types};
    }

    function map(e:TypedExpr):hscript.Expr {
        if (e == null) return null;

        inline function mapArray(arr:Array<TypedExpr>):Array<hscript.Expr> {
            return [for (p in arr) map(p)];
        }

        inline function registerStdType(type:Array<String>) {
            types.set(type.join("."), type.copy());
        }

        inline function registerBaseType(type:BaseType):Void {
            var t = BaseTypeTools.baseTypePath(type);
            types.set(t.join("."), t);
        }

        inline function patchVarName(v:TVar) {
            return if (v.name == "`") v.name + TypeTools.getFullPath(v.t).pop(); else v.name;
        }

        return switch e.expr {
            case TConst(TInt(c)): EConst(CInt(c));
            case TConst(TFloat(c)): EConst(CFloat(Std.parseFloat(c)));
            case TConst(TString(c)): EConst(CString(c));
            case TConst(TBool(c)): EIdent(c ? "true" : "false");
            case TConst(TNull): EIdent("null");
            case TConst(TThis): EIdent("this");
            case TConst(TSuper): EIdent("super");
            case TEnumIndex(e1): throw "unsuported"; // TODO:
            case TIdent(s): EIdent(s);
            case TLocal(v):
                var type = convertType(e.t, e.pos);
                // magic "`trace" method in js target
                if (v.name == "`trace") {
                    var type = ["haxe", "Log"];
                    registerStdType(type);
                    type.push("trace");
                    pathToHExpr(type);
                }
                else {
                    EIdent(patchVarName(v));
                }

            case TArray(e1, e2): EArray(map(e1), map(e2));
            case TBinop(OpAssignOp(op), e1, e2): EBinop(binops.get(op) + "=", map(e1), map(e2));
            case TBinop(op, e1, e2): EBinop(binops.get(op), map(e1), map(e2));
            case TField(e, field):
                var f = fieldName(field);
                var res = null;
                var type = e.t;

                if (!Context.defined("html5") && !Context.defined("neko")) {
                    var isEnum = false;
                    switch e.t {
                        case TType(_.get() => t, _) if (t.name.indexOf("Enum<") == 0): isEnum = true;
                        case _:
                    }
                    if (isEnum) switch field {
                        case FEnum(_.get() => e, f) if (e.meta.has(":fakeEnum")):
                            var meta = e.meta.get();
                            for (m in meta) if (m.name == ":fakeEnum") {
                                convertType(type, e.pos);
                                res = switch m.params {
                                    case [{expr:EConst(CIdent("String"))}]:
                                        EConst(CString(f.name));
                                    case [{expr:EConst(CIdent("Int"))}]:
                                        EConst(CInt(f.index));
                                    case _:
                                        throw "unknown fake enum";
                                }
                                break;
                            }
                        case _:
                    }
                }
                if (res == null) res = switch e.expr {
                    case TConst(TSuper):
                        pathToHExpr(["this", superReplacer.replaceName(f)]);
                    case _:
                        convertType(type, e.pos);
                        EField(map(e), f);
                }
            res;

            case TTypeExpr(cl):
                var baseType = baseTypeFromModuleType(cl);
                registerBaseType(baseType);
                var path = BaseTypeTools.baseTypePath(baseType);
                pathToHExpr(path);

            case TParenthesis(e): EParent(map(e));
            case TObjectDecl(fields): EObject([for (f in fields) {name:f.name, e:map(f.expr)}]);
            case TArrayDecl(el): EArrayDecl(mapArray(el));
            case TCall(e, params):
                switch e.expr {
                    case TField(f, FEnum(_, ef)):
                        convertType(f.t, f.pos);
                        var t = ["Type"];
                        registerStdType(t);
                        t.push("createEnum");
                        ECall(pathToHExpr(t), [map(f), EConst(CString(ef.name)), EArrayDecl(mapArray(params))]);
                    case _:
                        convertType(e.t, e.pos);
                        ECall(map(e), mapArray(params));
                }

            case TNew(tp, _, params):
                var bs = tp.get();
                registerBaseType(bs);
                var path = BaseTypeTools.baseTypePath(bs);
                ENew(path.join("."), mapArray(params));
            
            case TUnop(op, postFix, e): EUnop(unops.get(op), !postFix, map(e));
            case TFunction(func):
                var args = [];
                for (arg in func.args) {
                    if (arg.value != null) {
                        Context.warning("default args not implemented. 0/false/null will be used", e.pos);
                    }
                    args.push({name:arg.v.name, opt:arg.value != null, t:convertType(arg.v.t, e.pos) } );
                }
                EFunction(args, map(func.expr), null, convertType(func.t, e.pos));

            case TVar(v, expr): EVar(patchVarName(v), convertType(v.t, e.pos), map(expr));
            case TBlock(el): EBlock(mapArray(el));
            case TFor(v, it, expr): EFor(patchVarName(v), map(it), map(expr));
            case TIf(econd, eif, eelse): EIf(map(econd), map(eif), map(eelse));
            case TWhile(econd, e, true): EWhile(map(econd), map(e));
            case TWhile(econd, e, false):

                var expr = map(e);
                var breakedName = "___breaked" + (++breakedId);
                EBlock([
                    EVar(breakedName,null,EIdent("true")),
                    EWhile(EIdent("true"),EBlock([expr,EBinop("=",EIdent(breakedName),EIdent("false")),EBreak])),
                    EIf(EUnop("!",false,EIdent(breakedName)),EWhile(map(econd), expr),null)
                ]);

            case TSwitch(e, cases, edef):

                var res:Array<{values:Array<hscript.Expr>, expr:hscript.Expr}> = [];
                for (c in cases) {
                    res.push({expr:map(c.expr), values:mapArray(c.values)});
                }
                ESwitch(map(e), res, map(edef));

            case TTry(etry, catches):
                if (catches.length > 1) {
                    Context.warning("halk support only one catch. Last catch will be used", e.pos);
                }
                var c = catches[catches.length - 1];
                ETry(map(etry), patchVarName(c.v), convertType(c.v.t, e.pos), map(c.expr));

            case TReturn(e): EReturn(map(e));
            case TBreak: EBreak;
            case TContinue: EContinue;
            case TThrow(e): EThrow(map(e));
            case TCast(e, t):
                var a = map(e);
                if (t != null) {
                    var baseType = baseTypeFromModuleType(t);
                    registerBaseType(baseType);
                    var path = BaseTypeTools.baseTypePath(baseType);
                    registerStdType(["Std"]);
                    EIf(ECall(pathToHExpr(["Std", "is"]),[a,pathToHExpr(path)]),a,EThrow(EConst(CString('can\'t cast "${a.toString()}" to "${path.join(".")}"'))));
                }
                else {
                    a;
                }

            case TMeta(_, e): map(e);
            case TEnumParameter(e1, _, idx):
                convertType(e1.t, e1.pos);
                var t = ["Type"];
                registerStdType(t);
                t.push("enumParameters");
                EArray(ECall(pathToHExpr(t), [map(e1)]), EConst(CInt(idx)));
        };
    }

    inline function fieldName(field:haxe.macro.FieldAccess):String {
        return switch field {
            case FInstance(_, _, t) | FStatic(_, t) | FAnon(t) | FClosure(_, t): t.get().name;
            case FDynamic(s): s;
            case FEnum(_, ef): ef.name;
        };
    }

    inline function pathToHExpr(path:Array<String>):hscript.Expr {
        path = path.copy();
        var res = EIdent(path.shift());
        while (path.length > 0) res = EField(res, path.shift());
        return res;
    }

    inline function baseTypeFromModuleType(t:haxe.macro.ModuleType):BaseType {
        return switch t {
            case TClassDecl(r): r.get();
            case TEnumDecl(r): var res = r.get();
                // patch for enums
                // haxe rename enums, remove module name from path
                // test.Module.EnumName -> test.EnumName
                var path = res.module.split(".");
                path.pop();
                res.module = path.join(".");
                res;
            case TTypeDecl(r): r.get();
            case TAbstract(r): r.get();
        }
    }

    inline function convertType(type:haxe.macro.Type, pos:Position):CType {
        return convertComplexType(TypeTools.toComplexType(type), pos);
    }

    function convertTypePath(p:TypePath, pos:Position):CType {
        var path:Array<String> = null;
        var sub = null;
        if (p.sub != null) {
            if (p.sub.indexOf("Class<") == 0) sub = p.sub.substring(6, p.sub.length-1);
            else if (p.sub.indexOf("Enum<") == 0) sub = p.sub.substring(5, p.sub.length-1);
            if (sub != null) path = sub.split(".");
            else sub = p.sub;
        }

        if (path == null) {
            path = p.pack.length > 0 ? p.pack.concat([p.name]) : [p.name];
            if (sub != null) {
                var subPath = sub.split(".");
                path.push(subPath[subPath.length - 1]);
            }
        }

        try {
            var type = Context.getType(path.join("."));
            var fullPath = TypeTools.getFullPath(type);
            if (fullPath != null) path = fullPath;
        } catch (e:Dynamic) {}

        if (path[0] == "StdTypes") {
            path.shift();
        }
        if (path.length == 0) return null;

        types.set(path.join("."), path);
        return CTPath(path, null);
    }

    function convertComplexType(type:ComplexType, pos:Position):CType {
        if (type == null) return null;

        inline function processAnonFields(fields:Array<Field>) {
            var res = [];
            for (f in fields) {
                var name = f.name;
                var meta = cast(f.meta);
                switch f.kind {
                    case FVar(t, e):
                        if (e != null) Context.error('default values are not supported in anonymous structs', pos);
                        res.push({name: name, t: convertComplexType(t, pos), meta: meta});

                    case FProp(_, _):
                        Context.error('properties are not supported in anonymous structs', pos);

                    case FFun(f):
                        var type = CTFun([for (a in f.args) convertComplexType(a.type, pos)], convertComplexType(f.ret, pos));
                        res.push({name: name, t: type, meta: meta});
                }
            }
            return res;
        }

        return switch type {
            case TPath(p):
                convertTypePath(p, pos);
            case TFunction(args, ret): CTFun([for (a in args) convertComplexType(a, pos)], convertComplexType(ret, pos));
            case TAnonymous(fields): CTAnon(processAnonFields(fields));
            case TParent(t): CTParent(convertComplexType(t, pos));
            case TExtend(p, fields):
                for (t in p) convertTypePath(t, pos);
                CTAnon(processAnonFields(fields));

            case TOptional(t): convertComplexType(t, pos);
            case TIntersection(tl): throw "unsupported"; // TODO:
            case TNamed(n, t): CTNamed(n, convertComplexType(t, pos));
        }
    }
}

#end