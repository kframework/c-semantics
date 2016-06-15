module C-STMT-RETURN
     imports C-SYNTAX
     imports C-CONFIGURATION

     rule <k> Return(V:RValue) => .K ...</k>
          <elab>... .K => Return(V) </elab>

endmodule
