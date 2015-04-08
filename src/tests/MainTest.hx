package tests;
import haxe.io.Path;
import halk.Live;
import halk.ILive;
class MainTest implements ILive {
    public function new() {
    }

    @liveUpdate @live function test2() {
        this.test(1, true);
    }

    var i:String = "tada";

    @live function test(a:Int, b:Bool) {
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
        trace(Std.string(t) + " 23");

        trace(this.i);
        for (r in a) trace(r);
    }
}
