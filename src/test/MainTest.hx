package test;
import haxe.io.Path;
import halk.ILive;


class Root {
    function rootA() {
        trace("super");
    }

    public var a:String;
    public var b(get_b, never):String;
    @:isVar public var c(never, set_c):String;

    function get_b() return "Root::b";
    function set_c(value) {
        trace(value);
        return c = value;
    }
}

@live class MainTest extends Root implements ILive {
    public function new() {
        test2();
    }

    @liveUpdate function test2() {
        this.test(1, true);
    }

    var i:String = "tada";

    function test(a:Int, b:Bool) {
        super.rootA();
        trace(super.b);
        super.c = "TOTO";
        trace("live");
        var i = 9;
        do {
            trace(i);
        }while (i++ < 10);
        var a:Array<Int> = [1];
        a = new Array();
        a = new Array<Int>();

        var p:Path = new Path("/root/lib");

        a[0] = 1;
        (a[0]);
        (1 + 2) * 3;
        trace("test");
        var t:{q:Int, s:Int} = {q:1, s:2};
        trace(a);
        trace(p.toString());
        trace(Std.int(2) + " 23");
        trace(this.i);
        for (r in [13]) trace(r);
    }
}
