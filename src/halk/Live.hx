package halk;

import haxe.Resource;
import halk.Macro.MacroContext;

#if halk_angry

#if sys
import sys.thread.Thread;
import sys.io.File;
#else
import haxe.Http;
#end

using StringTools;


class Live {


    static public var instance(default, null) = new Live();

    static public function isActive() { return true; }

    var listeners = new Array<Void->Void>();

    var interp:HalkInterp = new HalkInterp();

    var data:MacroContext;

    var methods:Map<String, Dynamic>;

    function new() {
        #if halk
        delayedCall(firstLoad, 100);
        #end
    }

    inline function nextLoad() {
        delayedCall(load, 100);
    }

    function firstLoad() {
        var cont = Resource.getString(MacroContext.LIVE_FILE_NAME);
//        trace(cont);
        if (cont != null) onData(cont);
        else onError(null);
    }

    function load() {
        #if sys
//        trace(sys.FileSystem.readDirectory(Sys.getCwd()));
        var data:String = null;
        try {
            data = File.getContent(MacroContext.LIVE_FILE_NAME);
        } catch (e:Dynamic) {
            onError(e);
            return;
        }
        onData(data);
        #else
        var loader = new Http(MacroContext.LIVE_FILE_NAME);
        loader.onData = onData;
        loader.onError = onError;
        loader.request();
        #end
    }

    function onData(data:String) {
        nextLoad();
        process(data);
    }

    function onError(e:Dynamic) {
        trace(e);
        nextLoad();
    }

    function process(str:String):Void {
        if (str == null) return;

        if (data != null && data.version == MacroContext.getVersion(str)) {
            return;
        }

        var newData:MacroContext = MacroContext.fromFile(str);

        if (newData == null) {
            return;
        }

        data = newData;

        interp = new HalkInterp();
        var vars:Map<String, Dynamic> = interp.variables;

        #if js
        vars["__new__"] = function (t) return untyped __new__(t);
        #end

        for (n in data.types.keys()) {
            var t:Array<String> = data.types[n];
//            trace(n + " -> " + t);
            var type:Dynamic = Type.resolveClass(n);
            if (type == null) type = Type.resolveEnum(n);
            if (type == null) continue;

            var name = t.pop();
            var end = null;
            for (s in t) {
                if (end == null) {
                    if (!vars.exists(s)) vars.set(s, end = {});
                    else end = vars.get(s);
                }
                else
                {
                    if (!Reflect.hasField(end, s)) {
                        var newEnd = {};
                        Reflect.setField(end, s, newEnd);
                        end = newEnd;
                    } else {
                        end = Reflect.field(end, s);
                    }
                }
            }
            if (end == null) {
                vars.set(n, type);
            } else {
                Reflect.setField(end, name, type);
            }
        }

//        trace(vars);
//        for (m in data.methods) { trace(new hscript.Printer().exprToString(m)); };

        methods = [for (m in data.methods.keys()) m => interp.execute(data.methods[m])];

//        trace(methods);

        updateListeners();
    }

    public function call<T>(ethis:T, method:String, args:Array<Dynamic>):Dynamic {
        if (data == null) return null;
    //    trace("call " + method + " " + methods.get(method));
        interp.variables.set("this", ethis);
        return Reflect.callMethod(ethis, methods.get(method), args);
    }

    public function addListener(listener:Void->Void):Void {
//        trace('register listener $listener');
        removeListener(listener);
        listeners.push(listener);
    }

    public function removeListener(listener:Void->Void):Void {
        if (listeners.remove(listener)) {
//            trace('unregister listener $listener');
        }
    }

    inline function updateListeners() {
        for (l in listeners.copy()) l();
    }

    static function delayedCall(f:Void->Void, time:Int) {
        #if sys
        Thread.create(function() {
            Sys.sleep(time / 1000);
            f();
        });
        #else
        haxe.Timer.delay(f, time);
        #end
    }
}

#end
