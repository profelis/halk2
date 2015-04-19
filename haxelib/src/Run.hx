package ;

import Run.BuildConfig;
import haxe.Unserializer;
import haxe.Serializer;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Input;
import sys.io.Process;
import Sys.println in out;

using StringTools;

enum BuildType {
    DefaultBuild;
    HalkBuild;
    HalkUpdateBuild;
}

enum ProjectType {
    HxmlProject;
    LimeProject;
}

class BuildConfig {

    public var haxeArgs:String;
    public var projectType:ProjectType;

    public function new() {}
}

class Run {

    static inline var CONFIG_FILE = "halk.config";

    static function main() {
        var r = new Run();
        r.exec(Sys.args());
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
        if (args.length > 0) {
            var f = args[args.length - 1];
            if (FileSystem.exists(f) && FileSystem.isDirectory(f)) {
                Sys.setCwd(f);
                args.pop();
            }
        }

        processHalkArgs(args);

        if (args.length == 0) {
            printHelp();
            return;
        }

        var firstArg = args[0];
        if (firstArg.endsWith(".hxml")) {
            execHxml(args);
        } else {
            execLime(args);
        }

    }

    function execHxml(args:Array<String>) {
        var p:Process;

        inline function redirectOutput() {
            // TODO: async read stdout
            var s:String;
            while (null != (s = readLine(p.stderr))) {
                Sys.stderr().writeString(s + "\n");
            }

            while (null != (s = readLine(p.stdout))) {
                Sys.stdout().writeString(s + "\n");
            }
        }

        switch buildType {
            case DefaultBuild:
                deleteBuildConfig();

                out("$ haxe  " + args.join(" "));
                p = new Process("haxe", args);
                redirectOutput();
                if (p.exitCode() != 0) Sys.exit(p.exitCode());

            case HalkBuild:
                deleteBuildConfig();

                args.push("-D");
                args.push("halk");
                args.push("-lib");
                args.push("halk");
                out("$ haxe  " + args.join(" "));
                p = new Process("haxe", args);
                redirectOutput();

                if (p.exitCode() != 0) Sys.exit(p.exitCode());

                var cfg:BuildConfig = new BuildConfig();
                cfg.haxeArgs = args.join(" ");
                cfg.projectType = HxmlProject;
                storeBuildConfig(cfg);

            case HalkUpdateBuild:

                var cfg = readBuildConfig();
                if (cfg == null || !cfg.projectType.match(HxmlProject)) {
                    out("Error: rebuild project with -halk flag");
                    Sys.exit(1);
                }
                var args = cfg.haxeArgs.split(" ");
                args.push("--no-output");
                out("$ haxe  " + args.join(" "));
                p = new Process("haxe", args);
                redirectOutput();

                if (p.exitCode() != 0) Sys.exit(p.exitCode());
        }
    }

    function execLime(args:Array<String>) {
        var haxeArgs = "";
        inline function parseHaxeExec(s:String) {
            var r = ~/Running command.*?haxe\s(.*)/;
            if (r.match(s)) {
                haxeArgs = r.matched(1).trim();
            }
        }

        var p:Process;

        inline function redirectOutput(logOut:Bool, logError:Bool, parse = false) {
            var s:String;
            var del = Sys.systemName() == "Windows" ? "\n\r" : "\n";

            if (logOut) {
                var out = Sys.stdout();
                try {
                    while (true) {
                        s = p.stdout.readLine();
                        if (parse) parseHaxeExec(s);
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
                        if (parse) parseHaxeExec(s);
                        err.writeString(s + del);
                        err.flush();
                    }
                } catch (e:Dynamic) {}
            }
        }

        switch buildType {
            case DefaultBuild:
                deleteBuildConfig();

                args.unshift("lime");
                args.unshift("run");
                out("$ haxelib  " + args.join(" "));
                p = new Process("haxelib", args);
                redirectOutput(true, true);

                if (p.exitCode() != 0) Sys.exit(p.exitCode());

            case HalkBuild:
                deleteBuildConfig();

                args.unshift("lime");
                args.unshift("run");
                args.push("-Dhalk");
                args.push("-v");
                args.push("--haxelib=halk");
                out("$ haxelib  " + args.join(" "));
                p = new Process("haxelib", args);
                redirectOutput(true, true, true);

                if (p.exitCode() != 0) Sys.exit(p.exitCode());

                var cfg:BuildConfig = new BuildConfig();
                cfg.haxeArgs = haxeArgs;
                cfg.projectType = LimeProject;
                storeBuildConfig(cfg);

            case HalkUpdateBuild:

                var cfg = readBuildConfig();
                if (cfg == null || !cfg.projectType.match(LimeProject)) {
                    out("Error: rebuild project with -halk flag");
                    Sys.exit(1);
                }
                var args = cfg.haxeArgs.split(" ");
                args.push("--no-output");
                out("$ haxe  " + args.join(" "));
                p = new Process("haxe", args);
                redirectOutput(false, true);

                if (p.exitCode() != 0) Sys.exit(p.exitCode());
        }
    }

    function readBuildConfig():BuildConfig {
        if (!FileSystem.exists(CONFIG_FILE)) {
            return null;
        }

        var cont = File.getContent(CONFIG_FILE);
        var cfg:BuildConfig = cast Unserializer.run(cont);
        return cfg;
    }

    function deleteBuildConfig() {
        if (FileSystem.exists(CONFIG_FILE)) {
            FileSystem.deleteFile(CONFIG_FILE);
        }
    }

    function storeBuildConfig(config:BuildConfig) {
        Serializer.USE_ENUM_INDEX = true;
        File.saveContent(CONFIG_FILE, Serializer.run(config));
    }

    function readLine(input:Input) {
        return try {
            input.readLine();
        } catch (e:Dynamic) { null; }
    }

    function printHelp() {
        out("Use 'haxelib run halk <build>.hxml' or 'haxelib run halk test flash ...' for openfl project");
    }
}
