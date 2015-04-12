package test;
import haxe.io.Path;
import halk.Live;
import halk.ILive;

enum A {
    C1;
    C2(i:Int);
}

class MainTest implements ILive {
    public function new() {
        trace(A.C1);
    }

    @liveUpdate function test2() {
        this.test(1, true);
    }

    var i:String = "tada";

    @live function test(a:Int, b:Bool) {
        trace("live");
        trace(A);
        trace(switch (C2(10)) {
            case C2(b): b;
            case C1: 0;

        });
        var i = 9;
        do {
            trace(i);
        }while (i++ < 10);
        var a:Array<Int> = [1];
        a = new Array();
        a = new Array<Int>();

        var l:Live;
        var p:Path = new Path("/root/lib");

        a[0] = 1;
        (a[0]);
        (1 + 2) * 3;
        trace("test");
        var t:{q:Int, s:Int} = {q:1, s:2};
        trace(a);
        trace(b);
        trace(p.toString());
        trace(Std.string(2) + " 23");
        trace(this.i);
        for (r in [12]) trace(r);
    }
}
