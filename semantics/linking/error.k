module TRANSLATION-ERROR
     imports C-CONFIGURATION
     imports STRING
     imports K-IO
     imports ERROR-SYNTAX

     rule <k> EXIT(E:ErrorMsg) => reportError(E, S, Loc, .K) ~> HALT ...</k>
          <curr-scope> S::Scope </curr-scope>
          <curr-program-loc> Loc::CabsLoc </curr-program-loc>
          <curr-eval-context> eval </curr-eval-context>

endmodule
