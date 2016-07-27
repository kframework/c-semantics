module CPP-EXPR-UNARY
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule *(prv(Loc:SymLoc, T:CPPPointerType))
          => lv(Loc, innerType(T))

endmodule
