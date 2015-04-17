package halk.macro;

#if macro

import haxe.macro.Expr.MetadataEntry;

class MetaTools {

    static public inline function findMeta(meta:Array<MetadataEntry>, name:String):MetadataEntry {
        var res = null;
        for (m in meta) {
            if (m.name == name) {
                res = m;
                break;
            }
        }
        return res;
    }
}

#end