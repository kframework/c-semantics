module LIBC-STRING
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-ERROR-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX

     // try to use getString
     // fixme should detect overlaps
     syntax KItem ::= strcpy(SymLoc, SymLoc, SymLoc)
     rule builtin("strcpy",
               tv(Dest:SymLoc, ut(_, pointerType(_))),
               tv(Src:SymLoc, ut(_, pointerType(_))))
          => strcpy(Dest, Src, Dest)
          requires Dest =/=K NullPointer andBool Src =/=K NullPointer
          [structural]

     rule (.K => UNDEF("STRING1", "Null pointer passed to strcpy.", "7.1.4:1, J.2:1 item 108"))
          ~> builtin("strcpy",
               tv(Dest:SymLoc, ut(_, pointerType(_))),
               tv(Src:SymLoc, ut(_, pointerType(_))))
          requires Dest ==K NullPointer orBool Src ==K NullPointer

     rule (.K => reval(nclv(Src:SymLoc, type(char))))
          ~> strcpy(_, (Src => Src +bytes 1), _)
          [structural]

     rule (reval(tv(I:Int, T::UType)) => write(Dest, I, type(T)))
          ~> strcpy((Dest:SymLoc => Dest +bytes 1), _, _)
          requires I =/=Int 0
          [structural]
     rule reval(tv(0, T::UType))
          ~> strcpy(Dest:SymLoc, _, Orig:SymLoc)
          => write(Dest, 0, type(T))
          ~> tv(Orig, utype(pointerType(type(char))))
          [structural]
endmodule
