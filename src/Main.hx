package ;


import halk.ILive;
import test.Tests;
import lime.app.Application;


class Main extends Application implements ILive {

    public function new () {
        super ();
    }

    @liveUpdate public function live() {

        Tests.main();
    }


}