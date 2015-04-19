package ;

import projects.*;
import sys.FileSystem;
import Sys.println in out;

using StringTools;

enum BuildType {
    DefaultBuild;
    HalkBuild;
    HalkUpdateBuild;
}

class Run {

    static function main() {

        var args = Sys.args();
        if (args.length > 0) {
            var f = args[args.length - 1];
            if (FileSystem.exists(f) && FileSystem.isDirectory(f)) {
                Sys.setCwd(f);
                args.pop();
            }
        }

        var r = new Run();
        r.exec(args);
    }

    public function new() {}

    var buildType:BuildType;

    function processHalkArgs(args:Array<String>) {
        buildType = DefaultBuild;
        for (a in args) {
            if (a.startsWith("-halk")) {
                args.remove(a);
                buildType = if (a.length > 5) HalkUpdateBuild; else HalkBuild;
                break;
            }
        }
    }

    public function exec(args:Array<String>) {
        processHalkArgs(args);

        if (args.length == 0) {
            printHelp();
            return;
        }

        var projects = [new HxmlProject(), new LimeProject()];
        var builded = false;
        for (p in projects) {
            if (p.allowArgs(args)) {
                builded = true;
                p.build(buildType, args);
                break;
            }
        }
        if (!builded) printHelp();
    }

    function printHelp() {
        out("Use 'haxelib run halk <build>.hxml' or 'haxelib run halk test flash ...' for openfl project");
        out("more info https://github.com/profelis/halk2");
    }
}
