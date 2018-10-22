module C-STMT-BREAK
     imports C-CONFIGURATION
     imports C-SYNTAX

     rule <k> Break() => .K ...</k>
          <elab>... .K => Break() </elab>

endmodule
