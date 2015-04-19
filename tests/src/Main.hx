package ;

#if lime

import halk.ILive;
import test.Tests;
import lime.app.Application;


class Main extends Application implements ILive {

    public function new () {
        super ();

        #if !halk_angry
        live();
        #end
    }

    @liveUpdate public function live() {
        Tests.main();
    }
}
#end