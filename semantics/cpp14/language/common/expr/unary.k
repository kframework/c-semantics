module CPP-EXPR-UNARY
     imports INT
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule *(prv(Loc:SymLoc, Tr::Trace, T:CPPPointerType))
          => lv(Loc, combine(Tr, #klabel(`*__CPP-SYNTAX`)), innerType(T))

     rule &(lv(Loc:SymLoc, Tr::Trace, T::CPPType))
          => prv(Loc, combine(Tr, #klabel(`&__CPP-SYNTAX`)), type(pointerType(T)))

     context - (HOLE:Expr => reval(HOLE)) [result(PRVal)]
     rule - prv(I:Int, Tr::Trace, T::CPPType)
          => arithInterpret(T, 0 -Int I, combine(Tr, #klabel(`-__CPP-SYNTAX`)))
          requires isPromoted(T)

     context + (HOLE:Expr => reval(HOLE)) [result(PRVal)]
     rule + prv(I:Int, Tr::Trace, T::CPPType)
          => arithInterpret(T, I, combine(Tr, #klabel(`+__CPP-SYNTAX`)))
          requires isPromoted(T)

endmodule
