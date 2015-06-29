module C-STMT-RETURN
     imports C-SYNTAX

     rule <k> Return(V:RValue) => .K ...</k>
          <elab>... .K => Return(V) </elab>

endmodule
