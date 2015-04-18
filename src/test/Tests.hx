package test;

import buddy.Buddy;
import buddy.BuddySuite;

#if js
@reporter("buddy.reporting.TraceReporter")
#else
@reporter("buddy.reporting.ConsoleReporter")
#end
class Tests implements Buddy {}
