module LIBC-STRING
     imports COMMON-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS
     imports URIS
     imports C-CONFIGURATION

     imports LIBC-SYNTAX
     
     // try to use getString
     // fixme should detect overlaps
     syntax K ::= "strcpy" "(" SymLoc "," SymLoc "," SymLoc ")"
     rule [strcpy-start]:
          prepareBuiltin((Identifier("strcpy")), 
               (tv(Dest:SymLoc, t(_, pointerType(_))),, 
               tv(Src:SymLoc, t(_, pointerType(_)))))
          => strcpy(Dest, Src, Dest)
          [structural]
          
     rule [strcpy-pre]:
          (. => read(Src:SymLoc, t(.Set, char))) 
          ~> strcpy(_, (Src => Src +bytes 1), _)
          [structural]
     
     rule [strcpy-some]:
          (tv(I:Int, T:KResult) => write(lv(Dest, t(.Set, char)), tv(I, T)))
          ~> strcpy((Dest:SymLoc => Dest +bytes 1), _, _)
          when I =/=Int 0
          [structural]
     rule [strcpy-done]:
          tv(0, T:KResult) 
               ~> strcpy(Dest:SymLoc, _, Orig:SymLoc)
          => write(lv(Dest, t(.Set, char)), tv(0, T)) 
               ~> tv(Orig, t(.Set, pointerType(t(.Set, char))))
          [structural]
endmodule
