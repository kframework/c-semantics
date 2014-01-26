module LIBC-STDDEF
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DECL-SYNTAX
     imports C-BITS-SYNTAX
     imports C-SETTINGS-SYNTAX

     syntax K ::= "offsetOf" "(" K "," K ")" [strict(1)]
     rule OffsetOf(T:KResult, K:K, F:Id)
          => offsetOf(DeclType(T:KResult, K:K), F:Id)
          [structural]

     // fixme should check for bitfield offset
     rule <k> 
               offsetOf(t(_, structType(S:Id)), F:Id)
               => tv(bitsToBytes(Offset:Int), cfg:sizeut)
          ...</k>
          <structs>...
               S:Id |-> aggregateInfo(_, _, (_ F:Id |-> Offset:Int))
          ...</structs>
          [structural]

     rule offsetOf(t(_, unionType(_:Id)), _) => tv(0, cfg:sizeut)
          [structural]
endmodule
