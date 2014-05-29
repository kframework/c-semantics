module LIBC-TIME
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     
     // fixme, just a placeholder
     rule [time]:
          prepareBuiltin(Identifier("time"), 
               ListItem(_:KResult))
          => tv(0, t(.Set, long-long-int))
          [structural]
endmodule

