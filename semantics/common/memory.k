module C-COMMON-MEMORY-SYNTAX
     syntax K ::= "mconst"

     syntax K ::= makeUnwritable(SymLoc)
     syntax K ::= makeUnwritableSubObject(K)
     syntax K ::= makeUnwritableVar(K)

     syntax K ::= allocateType(SymLoc, Type)
     syntax K ::= allocateTypeIfAbsent(SymLoc, Type)
endmodule
