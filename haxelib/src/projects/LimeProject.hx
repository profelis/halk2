package projects;

import projects.AbstractProject;
import Sys.println in prln;

using StringTools;

class LimeProject extends AbstractProject {

    public function new() {
        super("lime");
    }

    override public function allowArgs(args:Array<String>):Bool {
        return ["build", "test", "clean", "update", "run", "deploy"].indexOf(args[0]) != -1;
    }

    function addLime(args:Array<String>):Void {
        args.unshift("lime");
        args.unshift("run");
    }

    public override function defaulBuild(args:Array<String>) {
        addLime(args);
        var p = execHaxelib(args);
        if (p.exitCode() != 0) Sys.exit(p.exitCode());
    }

    public override function halkBuild(args:Array<String>):Void {
        BuildConfig.deleteBuildConfig();

        addLime(args);
        args.push("-D" + AbstractProject.ACTIVATE_HALK);
        args.push("-v"); // read haxe args from verbose mode %)

        var p = exec("haxelib", args);
        var lines = redirectOutput(p, true, true);

        if (p.exitCode() != 0) Sys.exit(p.exitCode());

        var haxeArgs = null;

        var r = ~/Running command.*?haxe\s(.*)/;
        for (l in lines) {
            if (r.match(l)) {
                haxeArgs = r.matched(1).trim();
                break;
            }
        }

        if (haxeArgs != null) {
            storeConfig(haxeArgs.split(" "));
        }  else {
            prln("Error: Can't find haxe command in lime output. Very sad :(");
            Sys.exit(1);
        }
    }
}
