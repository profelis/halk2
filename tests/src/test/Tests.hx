package test;

import buddy.*;

#if js
@reporter("buddy.reporting.TraceReporter")
#else
@reporter("buddy.reporting.ConsoleReporter")
#end
class Tests implements Buddy<[test.AstTests]> {}
