require "check-loc.k"
require "compound-literal.k"
require "configuration.k"
require "error.k"
require "error-map.k"
require "io-direct.k"
require "process-label.k"
require "resolution.k"
require "settings.k"
require "static.k"

module C11-TRANSLATION
     imports C11-CONFIGURATION
     imports C11-ERROR
     imports C11-ERROR-MAP
     imports C11-SETTINGS
     imports C-CHECK-LOC
     imports C-IO-DIRECT
     imports C-PROCESS-LABEL
     imports C-COMPOUND-LITERAL
     imports C-DECLARATION-RESOLUTION
     imports C-STATIC
     imports C-DYNAMIC-SYNTAX

     rule <k> Program(klist(P:KList)) => klistToK(P) ...</k>
          //<nextLoc> _ => firstLoc(1) </nextLoc>
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


     rule <T>... <k> .K </k> ...</T> => .Bag
          
     // TODO(chathhorn): It'd be nice to remove sequence points altogether from
     // this part of the semantics.
     rule [sequencePoint]:
          sequencePoint => .
          [structural]

endmodule
