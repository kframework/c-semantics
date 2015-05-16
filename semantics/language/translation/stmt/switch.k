module C-STMT-SWITCH
     imports C-SYNTAX

     // TODO(chathhorn): check the case of statements in a switch that aren't
     // reachable via any label.
     rule <k> Switch(SN:Int, V:RValue, _) => .K ...</k>
          <elab>... .K => Switch(SN, V, .K) </elab>
          [structural]

endmodule
