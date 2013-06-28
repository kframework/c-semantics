module LIBC-TIME
     imports C-SEMANTIC-SYNTAX
     imports LIBC-BOOTSTRAP-SYNTAX
     
     // fixme, just a placeholder
     rule [time]:
          prepareBuiltin((Identifier("time")), _:KResult) 
          => tv(0, t(.Set, long-long-int))
          [structural]
endmodule

