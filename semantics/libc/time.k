module LIBC-TIME
     imports COMMON-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS
     imports URIS
     imports C-CONFIGURATION

     imports LIBC-SYNTAX
     
     // fixme, just a placeholder
     rule [time]:
          prepareBuiltin((Identifier("time")), _:KResult) 
          => tv(0, t(.Set, long-long-int))
          [structural]
endmodule

