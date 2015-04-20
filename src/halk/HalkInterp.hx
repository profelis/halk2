package halk;
import hscript.Interp;

class HalkInterp extends Interp {

    override function get( o : Dynamic, f : String ) : Dynamic {
//        trace(o + " " + f);
        if( o == null ) error(EInvalidAccess(f));
        return Reflect.getProperty(o,f);
    }

    override function set( o : Dynamic, f : String, v : Dynamic ) : Dynamic {
        if( o == null ) error(EInvalidAccess(f));
        Reflect.setProperty(o,f,v);
        return v;
    }

    override function fcall( o : Dynamic, f : String, args : Array<Dynamic> ) : Dynamic {
//        trace(o + " " + f);
        #if flash
        if (o == Std && f == "int") return call(Std, Std.int, args);
        #end
        return call(o, Reflect.field(o, f), args);
    }
//
//    override function call( o : Dynamic, f : Dynamic, args : Array<Dynamic> ) : Dynamic {
//        trace(o);
//        trace(f);
//        return Reflect.callMethod(o,f,args);
//    }

}
