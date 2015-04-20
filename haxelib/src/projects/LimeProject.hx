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
        args.push("--haxeflag=\"--no-inline\"");

        var p = exec("haxelib", args);
        var lines = redirectOutput(p, true, true);

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

//            if (p.exitCode() != 0) Sys.exit(p.exitCode());

        }  else {
            prln("Error: Can't find haxe command in lime output. Very sad :(");

//            if (p.exitCode() != 0) Sys.exit(p.exitCode());
            Sys.exit(1);
        }
    }
}
