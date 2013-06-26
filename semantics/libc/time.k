module LIBC-TIME
     imports C-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS
     imports C-CONFIGURATION

     imports LIBC-SYNTAX
     
     // fixme, just a placeholder
     rule [time]:
          prepareBuiltin((Identifier("time")), _:KResult) 
          => tv(0, t(.Set, long-long-int))
          [structural]
endmodule

