package projects;

import Run.BuildType;
import sys.io.Process;
import Sys.println in prln;

class AbstractProject {

    static inline var ACTIVATE_HALK = "halk_angry";

    var type:String;

    function new(type:String) {
        this.type = type;
    }

    // validate input args
    public function allowArgs(args:Array<String>):Bool {
        throw "override me";
    }

    // build project
    public inline function build(buildType:BuildType, args:Array<String>) {
        switch buildType {
            case BuildType.DefaultBuild: defaulBuild(args);
            case BuildType.HalkBuild: halkBuild(args);
            case BuildType.HalkUpdateBuild: incrementalBuild(args);
        }
    }

    function defaulBuild(args:Array<String>) {
        throw "override me";
    }

    function halkBuild(args:Array<String>):Void {
        throw "override me";
    }

    function incrementalBuild(args:Array<String>):Void {
        var cfg = BuildConfig.readBuildConfig();
        if (cfg == null || cfg.projectType != type) {
            prln("Error: Invalid config. Rebuild project with -halk flag");
            Sys.exit(1);
        }

        var args = cfg.haxeArgs;
        args.push("--no-output");

        var p = execHaxe(args);
        if (p.exitCode() != 0) Sys.exit(p.exitCode());
    }

    function redirectOutput(p:Process, logOut:Bool, logError:Bool):Array<String> {
        var s:String;
        var del = Sys.systemName() == "Windows" ? "\n\r" : "\n";
        var lines = [];

        if (logOut) {
            var out = Sys.stdout();
            try {
                while (true) {
                    s = p.stdout.readLine();
                    lines.push(s);
                    out.writeString(s + del);
                    out.flush();
                }
            } catch (e:Dynamic) {}
        }

        if (logError) {
            var err = Sys.stdout();
            try {
                while (true) {
                    s = p.stderr.readLine();
                    lines.push(s);
                    err.writeString(s + del);
                    err.flush();
                }
            } catch (e:Dynamic) {}
        }

        return lines;
    }

    function storeConfig(args:Array<String>) {
        var cfg:BuildConfig = new BuildConfig();
        cfg.haxeArgs = args;
        cfg.projectType = type;
        BuildConfig.storeBuildConfig(cfg);
    }

    function execHaxe(args:Array<String>):Process {
        var p = exec("haxe", args);
        redirectOutput(p, false, true);
        return p;
    }

    function execHaxelib(args:Array<String>):Process {
        var p = exec("haxelib", args);
        redirectOutput(p, true, true);
        return p;
    }

    function exec(cmd:String, args:Array<String>) {
        prln('- > $cmd ${args.join(" ")}');
        return new Process(cmd, args);
    }
}
