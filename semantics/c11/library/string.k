module LIBC-STRING
     imports C-CONFIGURATION
     imports INT
     imports K-EQUAL
     imports SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-NATIVE-BRIDGE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-IO-SYNTAX

     // try to use getString
     // fixme should detect overlaps
     syntax KItem ::= strcpy(SymLoc, SymLoc, SymLoc)
     rule builtin("strcpy",
               tv(Dest:SymLoc, ut(_, pointerType(_))),
               tv(Src:SymLoc, ut(_, pointerType(_))))
          => strcpy(Dest, Src, Dest)
          requires Dest =/=K NullPointer andBool Src =/=K NullPointer
          [structural]

     rule (.K => UNDEF("STRING1", "Null pointer passed to strcpy."))
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

     rule <k> builtin("strerror", tv(Err:Int, _)) => ErrStr ...</k>
          <strerror-cache>... Err |-> ErrStr::RValue ...</strerror-cache>
          [structural]
     rule <k> (.K => newFixedObject(nativeCall("strerror", ListItem(E), .List)))
               ~> builtin("strerror", tv(Err:Int, _) #as E::RValue)
          ...</k>
          <strerror-cache> Errs:Map </strerror-cache>
          requires notBool (Err in_keys(Errs))
          [structural]
     rule <k> ErrStr:RValue ~> builtin("strerror", tv(Err:Int, _))
               => ErrStr
          ...</k>
          <strerror-cache>... .Map => Err |-> ErrStr </strerror-cache>
          [structural]

     rule builtin("strerror_r", A1::RValue, A2::RValue, A3::RValue)
          => nativeCall("__xpg_strerror_r", ListItem(A1) ListItem(A2) ListItem(A3), .List)
          [native-call]
     rule builtin("__xpg_strerror_r", A1::RValue, A2::RValue, A3::RValue)
          => nativeCall("__xpg_strerror_r", ListItem(A1) ListItem(A2) ListItem(A3), .List)
          [native-call]

endmodule
