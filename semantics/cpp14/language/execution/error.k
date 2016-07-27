module CPP-EXECUTION-ERROR
     imports C-EXECUTION-ERROR-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule printStackTrace(L:List, Loc:CabsLoc, blockScope(X::QualId, _, _))
          => "  at " +String idToString(X) +String "(" +String printStackTrace(L, Loc, .K)

endmodule
