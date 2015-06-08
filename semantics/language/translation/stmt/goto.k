module C-STMT-GOTO
     imports C-SYNTAX
     imports C-CONFIGURATION

     rule <k> Goto(Lbl:CId) => .K ...</k>
          <elab>... .K => Goto(Lbl) </elab>

endmodule
