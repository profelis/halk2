import sys.io.File;
import sys.FileSystem;
import haxe.Serializer;
import haxe.Unserializer;

class BuildConfig {

    static inline var CONFIG_FILE = "halk.config";

    public var haxeArgs:Array<String>;
    public var projectType:String;

    public function new() {}

    public static function readBuildConfig():BuildConfig {
        if (!FileSystem.exists(CONFIG_FILE)) {
            return null;
        }

        var cont = File.getContent(CONFIG_FILE);
        var cfg:BuildConfig = cast Unserializer.run(cont);
        return cfg;
    }

    public static function deleteBuildConfig() {
        if (FileSystem.exists(CONFIG_FILE)) {
            FileSystem.deleteFile(CONFIG_FILE);
        }
    }

    public static function storeBuildConfig(config:BuildConfig) {
        Serializer.USE_ENUM_INDEX = true;
        File.saveContent(CONFIG_FILE, Serializer.run(config));
    }
}