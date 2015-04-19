package projects;

import projects.AbstractProject;
using StringTools;

class HxmlProject extends AbstractProject {

    public function new() {
        super("hxml");
    }

    override public function allowArgs(args:Array<String>):Bool {
        return args[0].endsWith(".hxml");
    }

    override function defaulBuild(args:Array<String>) {
        var p = execHaxe(args);
        if (p.exitCode() != 0) Sys.exit(p.exitCode());
    }

    override function halkBuild(args:Array<String>):Void {
        BuildConfig.deleteBuildConfig();

        args.push("-D");
        args.push(AbstractProject.ACTIVATE_HALK);
        args.push("--no-inline");

        var p = execHaxe(args);

        if (p.exitCode() != 0) Sys.exit(p.exitCode());

        storeConfig(args);
    }
}
