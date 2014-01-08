require "check-loc.k"
require "compound-literal.k"
require "configuration.k"
require "error.k"
require "io-direct.k"
require "process-label.k"
require "function-def.k"
require "resolution.k"
require "settings.k"
require "static.k"

module C11-TRANSLATION
     imports C11-CONFIGURATION
     imports C11-TRANS-ERROR
     imports C11-SETTINGS
     imports C-CHECK-LOC
     imports C-IO-DIRECT
     imports C-PROCESS-LABEL
     imports C-FUNCTION-DEF
     imports C-COMPOUND-LITERAL
     imports C-DECLARATION-RESOLUTION
     imports C-STATIC
     imports C-DYNAMIC-SYNTAX

     rule <k> Program(klist(P:KList)) => klistToK(P) ...</k>
          <threadLocal>...
               <control>...
                    <currentFunction> 
                         _ => file-scope
                    </currentFunction>
                    <currentProgramLoc>
                         _ => UnknownCabsLoc
                    </currentProgramLoc>
               ...</control>
          ...</threadLocal>
          <nextSharedLoc> _ => firstLoc(0) </nextSharedLoc>
          [structural, large]

     syntax SemMode ::= "InterpMode" | "DebugMode"
     rule <T>... <mode> InterpMode </mode> <k> .K </k> ...</T> => .Bag
          
     // TODO(chathhorn): It'd be nice to remove sequence points altogether from
     // this part of the semantics.
     rule [sequencePoint]:
          sequencePoint => .
          [structural]

endmodule
