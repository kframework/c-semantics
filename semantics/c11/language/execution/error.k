module C-EXECUTION-ERROR-SYNTAX
     imports LIST
     imports STRING-SYNTAX
     imports COMMON-SORTS
     imports C-DYNAMIC-SORTS
     imports ERROR-SYNTAX

     syntax String ::= printStackTrace(List, CabsLoc, Scope) [function, hook(C_SEMANTICS.printStackTrace), canTakeSteps]
endmodule

module C-EXECUTION-ERROR
     imports C-ERROR-SYNTAX
     imports C-EXECUTION-ERROR-SYNTAX
     imports C-CONFIGURATION
     imports K-IO
     imports K-REFLECTION
     imports STRING
     imports BITS-SYNTAX
     imports SETTINGS-SYNTAX
     imports C-DYNAMIC-SYNTAX

     rule assert(B::Bool, E::Error) => #if B #then .K #else E #fi [macro]

     rule <k> EXIT(E:ErrorMsg) => reportError(E, S, Loc, L) ~> HALT ...</k>
          <curr-scope> S::Scope </curr-scope>
          <curr-program-loc> Loc::CabsLoc </curr-program-loc>
          <call-stack> L::List </call-stack>

     // this rule prevents the open source semantics from getting stuck on this function
     rule printStackTrace(_, _, _) => ""

endmodule
