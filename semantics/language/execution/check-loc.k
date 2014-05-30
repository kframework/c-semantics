module C-CHECK-LOC
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX

     // fixme could additionally use the type to check whether that type is
     // valid for that pointer
     rule checkLoc(NullPointer) => .
     rule <k> checkLoc(loc(Base:SymBase, Offset:Int))
               => checkOffsets(Offset, Len)
          ...</k>
          <mem>... Base |-> object(_, Len:Int, _) ...</mem>
          [structural]
     rule <k> checkLoc(loc(Base:SymBase, 0)) => . ...</k>
          <functions>... Base |-> _ ...</functions>
          [structural]
     rule <k> checkLoc(loc((Base:SymBase => Base'), _)) ...</k>
          <linkings>... Base |-> Base':SymBase ...</linkings>
          [structural]
     rule <k> checkLoc(loc(Base:SymBase, _)) => errorLocInvalid ...</k>
          <mem> Mem:Map </mem>
          <functions> Funs:Map </functions>
          <linkings> Links:Map </linkings>
          when notBool Base in keys(Mem)
               andBool notBool Base in keys(Funs)
               andBool notBool Base in keys(Links)
          [structural]

     syntax KItem ::= checkOffsets(Int, Int) [function]
     rule checkOffsets(Offset:Int, Len:Int) => .
          when (Offset <=Int Len) andBool (Offset >=Int 0)
     rule checkOffsets(Offset:Int, Len:Int) => errorLocBounds
          when (Offset >Int Len) orBool (Offset <Int 0)

     syntax Error ::= "errorLocInvalid"
                    | "errorLocBounds"
     rule errorLocInvalid
          => UNDEF("ECL2", "Referring to an object outside of its lifetime.", "6.2.4")
          [structural]
     rule errorLocBounds
          => UNDEF("ECL3", "Found pointer that refers outside the bounds of an object + 1.", "6.2.4")
          [structural]
endmodule
