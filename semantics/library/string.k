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
     rule prepareBuiltin(Identifier("strcpy"),
               hrItem(tv(Dest:SymLoc, t(_, pointerType(_)))) hs::
               hrItem(tv(Src:SymLoc, t(_, pointerType(_)))))
          => strcpy(Dest, Src, Dest)
          requires Dest =/=K NullPointer andBool Src =/=K NullPointer
          [structural]
 
     rule (.K => UNDEF("STRING1", "Null pointer passed to strcpy.", "7.1.4:1, J.2:1 item 108"))
          ~> prepareBuiltin(Identifier("strcpy"),
               hrItem(tv(Dest:SymLoc, t(_, pointerType(_)))) hs::
               hrItem(tv(Src:SymLoc, t(_, pointerType(_)))))
          requires Dest ==K NullPointer orBool Src ==K NullPointer

     rule (.K => reval(nclv(Src:SymLoc, t(.Set, char))))
          ~> strcpy(_, (Src => Src +bytes 1), _)
          [structural]

     rule (reval(tv(I:Int, T:Type)) => write(Dest, I, T))
          ~> strcpy((Dest:SymLoc => Dest +bytes 1), _, _)
          requires I =/=Int 0
          [structural]
     rule reval(tv(0, T:Type))
          ~> strcpy(Dest:SymLoc, _, Orig:SymLoc)
          => write(Dest, 0, T)
          ~> tv(Orig, t(.Set, pointerType(t(.Set, char))))
          [structural]
endmodule
