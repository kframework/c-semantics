module C-STMT-BREAK
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-CONFIGURATION

     rule <k> Break => .K ...</k>
          <elab>... .K => Break </elab>

endmodule
