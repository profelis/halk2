package test;

import halk.ILive;
import buddy.BuddySuite;

using buddy.Should;

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
                a.returnThis().should.containExactly([true, false]);
            });

            it("test throws", function () {
                try {
                    a.doThrow(true);
                } catch (e:Dynamic) {
                    e.should.be(false);
                }
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

    function returnThis() {
        return s;
    }

    function doThrow(f:Bool) {
        if (f)
            throw false;
    }
}