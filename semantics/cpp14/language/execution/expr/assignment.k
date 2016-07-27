module CPP-EXPR-ASSIGNMENT
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule lv(Loc:SymLoc, T::CPPType) := prv(V::CPPValue, T'::CPPType)
          => write(Loc, convertType(utype(T), prv(V, T')), T)
          ~> lv(Loc, T)
          requires notBool isCPPClassType(T)

endmodule
