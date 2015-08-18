module LIBC-STRING
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports COMPAT-SYNTAX

     // try to use getString
     // fixme should detect overlaps
     syntax KItem ::= strcpy(SymLoc, SymLoc, SymLoc)
     rule prepareBuiltin(Identifier("strcpy"),
               hrItem(tv(Dest:SymLoc, t(_, pointerType(_)))) hs::
               hrItem(tv(Src:SymLoc, t(_, pointerType(_)))))
          => strcpy(Dest, Src, Dest)
          [structural]

     rule (.K => read(Src:SymLoc, t(.Set, char)))
          ~> strcpy(_, (Src => Src +bytes 1), _)
          [structural]

     rule (tv(I:Int, T:Type) => write(Dest, I, T))
          ~> strcpy((Dest:SymLoc => Dest +bytes 1), _, _)
          requires I =/=Int 0
          [structural]
     rule tv(0, T:Type)
          ~> strcpy(Dest:SymLoc, _, Orig:SymLoc)
          => write(Dest, 0, T)
          ~> tv(Orig, t(.Set, pointerType(t(.Set, char))))
          [structural]
endmodule
