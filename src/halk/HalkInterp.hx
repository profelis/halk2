package halk;
import hscript.Interp;

class HalkInterp extends Interp {

    override function get( o : Dynamic, f : String ) : Dynamic {
        if( o == null ) error(EInvalidAccess(f));
        return Reflect.getProperty(o,f);
    }

    override function set( o : Dynamic, f : String, v : Dynamic ) : Dynamic {
        if( o == null ) error(EInvalidAccess(f));
        Reflect.setProperty(o,f,v);
        return v;
    }

//    function fcall( o : Dynamic, f : String, args : Array<Dynamic> ) : Dynamic {
//        return call(o, Reflect.field(o, f), args);
//    }
//
//    function call( o : Dynamic, f : Dynamic, args : Array<Dynamic> ) : Dynamic {
//        return Reflect.callMethod(o,f,args);
//    }

}
