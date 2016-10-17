module CPP-EXECUTION-ERROR
     imports C-EXECUTION-ERROR-SYNTAX
     imports STRING
     imports COMPAT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule printStackTraceStart(Start:String, L:List, Loc:CabsLoc, blockScope(X::QualId, _, _))
          => Start +String idToString(X) +String "(" +String printStackTraceStart("   by ", L, Loc, .K)

endmodule
