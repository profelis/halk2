package test;

import haxe.io.Path;
import halk.ILive;
import buddy.BuddySuite;

using buddy.Should;

// TODO: super, nesting
// TODO: Abstract
class AstTests extends BuddySuite {
    public function new() {

        describe("Test ast expresions", function () {

            var a:ClassA;

            before(function () {
                a = new ClassA();
            });

            it("base tests", function () {
                a.returnInt().should.be(1);
                a.returnSwitch().should.be(3);
                a.returnIf().should.be(true);
                a.returnDate().should.be(DateTools.format(Date.now(), "%Y"));
                a.returnField().should.containExactly([true, false]);
            });

            it("test throws", function () {
                try {
                    a.doThrow(true);
                    fail();
                } catch (e:Dynamic) {
                    e.should.be(false);
                }
                a.doThrow(false).toString().should.be("/root/lib");
            });

            it("dynamic tests", function () {
                a.dynamicObjects().should.be("1 2 10");
            });

            it("array/map builders tests", function () {
                var m = a.arrayMapBuilders();
                var n = 0;
                for (i in m.keys()) {
                    i.should.be(m.get(i));
                    n++;
                }
                n.should.be(10);
            });

            it("do-while tests", function () {
                a.doWhile().should.be(11);
            });

            it("function.bind tests", function () {
                a.funcBind().should.be("22");
            });

            it("cast tests", function () {
                a.doCast().should.be(0);

                #if !cpp
                try {
                    trace(a.doBadCast());
                    fail();
                } catch(e:Dynamic) {}
                #end
            });

            it("enum tests", function () {
                a.execEnums().should.be(0);
                a.execIntEnum().should.be(true);
                a.execStringEnum().should.be(true);
                a.execAbstractEnum().should.be(true);
            });

            it("abstracts tests", function () {
               a.dynamicAbstract().should.be("foo");
            });
        });
    }
}

@live @:publicFields private class ClassA implements ILive {
    public function new() {}

    var s = [true, false];

    function returnInt() {
        return 1;
    }

    function returnSwitch() {
        var a = ["a"];
        a.push("b");
        return switch a
        {
            case ["b", _]:1;
            case ["a", "c"]:2;
            case ["a", "b"]:3;
            default:4;
        }
    }

    function returnIf() {
        var e = Math.min(1.0, 1e5);
        return if (e > 0) true; else false;
    }

    function returnDate() {
        var d = Date.now();
        return DateTools.format(d, "%Y");
    }

    function returnField() {
        return ((s));
    }

    function doThrow(f:Bool) {
        if (f)
            throw false;

        return new Path("/root/lib");
    }

    function dynamicObjects() {
        var a = {a:"1", b:2}, b = 10;
        return (function (a:{a:String, b:Int}) return ('${a.a} ${a.b} $b'))(a);
    }

    function arrayMapBuilders() {
        var a = [];
        for (i in 0...10) a.push(i);

        var b = [];
        var i = 0;
        while(i < 10) {
            b[i] = i;
            i++;
        }
        var c = [for (i in 0...10) a[i] => b[i]];

        return c;
    }

    function doWhile() {
        var i = 0;

        do {
            i++;
            if (i == 5) break;
        } while(i < 10);
        // i == 5
        var j = 0;
        do {
            i ++; // i == 6
        } while (j != 0);

        j = 0;
        #if !cpp
        do {
            j++;
            if (j > 5) continue;
            i++;
        } while (j < 10);
        #else
        i += 5;
        #end
        // i == 11
        return i;
    }

    function funcBind() {
        var f = function(a:Int, b:String) return b + a;

        var f2 = f.bind(_, "2");
        return f2(2);
    }

    function doCast() {
        var s:Dynamic = [1, 2];
        var a = cast(s, Array<Dynamic>);

        var i = a[0] + a[1]; // 3

        var b:Array<Int> = cast s;

        i += b[1]; // 5

        return i - 5;
    }

    function doBadCast() {
        var s:Dynamic = {o:0};
        var a = cast(s, Array<Dynamic>);
        return a.pop();
    }

    function execEnums() {
        var a = A2(10);

        return switch a {
            case EnumA.A1: 10;
            case A2(5): 5;
            case EnumA.A2(t): t - 10;
        }
    }

    @noLive function enumI1() return I1;

    function execIntEnum() {
        var a = I1;
        var b = enumI1();
        return a == b;
    }

    @noLive function enumS2() return S2;

    function execStringEnum() {
        var a = S2;
        var b = enumS2();
        return a == b;
    }

    @noLive function enumE2() return EnumAbstract.E2;

    function execAbstractEnum() {
        var a = EnumAbstract.E1;
        if (a == enumE2()) throw false;
        return EnumAbstract.E2 == enumE2();
    }

    function dynamicAbstract() {
        var a:DynamicAbstract<String> = {t:"foo"};
        return a.value();
    }
}

enum EnumA {
    A1;
    A2(c:Int);
}

@:fakeEnum(Int) enum EnumInt {
    I1;
    I2;
}

@:fakeEnum(String) enum EnumString {
    S1;
    S2;
}

@:enum abstract EnumAbstract(String) {
    var E1 = "a";
    var E2 = "b";
}

abstract DynamicAbstract<T>({t:T}) from {t:T} to {t:T} {

    public function value():Null<T> return this != null ? this.t : null;
}