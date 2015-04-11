package halk;
class MapTools {
    static public inline function add<K, V>(a:Map<K, V>, b:Map<K, V>):Void {
        for (k in b.keys()) {
            a.set(k, b.get(k));
        }
    }
}
