module LIBCPP-NEW
     imports LIBCPP-BOOTSTRAP-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports C-SETTINGS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule builtin(GlobalNamespace() :: operatornew[], V::Val)
          => builtin(GlobalNamespace() :: operatornew, V)

     rule <k> builtin(GlobalNamespace() :: operatornew, prv(Len::Int, _, _))
              => allocObject(Base, type(no-type), Len)
              ~> prv(addProv(fromArray(0, Len), lnew(Base, type(no-type))), noTrace,
                   type(pointerType(type(void))))
          ...</k>
          <malloced>... .Map => Base |-> Len ...</malloced>
          <next-newed> Base::SymBase => linc(Base) </next-newed>
          requires notBool hasLint andBool Len <=Int cfg:maxHeapBound

endmodule
