module C-STMT-RETURN
     imports C-CONFIGURATION
     imports C-SYNTAX
     imports C-DYNAMIC-SORTS

     rule <k> Return(V:RValue) => .K ...</k>
          <elab>... .K => Return(V) </elab>

endmodule
