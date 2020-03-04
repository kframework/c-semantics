module C-EXECUTION-ERROR-SYNTAX
     imports LIST
     imports MAP
     imports STRING-SYNTAX
     imports COMMON-SORTS
     imports C-DYNAMIC-SORTS
     imports ERROR-SYNTAX

     syntax List ::= printStackTrace(List, String, Scope, CabsLoc, Map) [function, hook(C_SEMANTICS.printStackTrace)]
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

     rule <k> EXIT(E:ErrorMsg) => reportError(E, Tu, S, Loc, REnv, L) ~> HALT ...</k>
          <curr-tu> Tu::String </curr-tu>
          <curr-scope> S::Scope </curr-scope>
          <curr-program-loc> Loc::CabsLoc </curr-program-loc>
          <call-stack> L::List </call-stack>
          <renv> REnv::Map </renv>

     // this rule prevents the open source semantics from getting stuck on this function
     rule printStackTrace(_, _, _, _, _) => .List

endmodule
