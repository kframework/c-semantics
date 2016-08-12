module CPP-EXPR-UNARY
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule *(prv(Loc:SymLoc, Tr::Trace, T:CPPPointerType))
          => lv(Loc, combine(Tr, #klabel(`*__CPP-SYNTAX`)), innerType(T))

endmodule
