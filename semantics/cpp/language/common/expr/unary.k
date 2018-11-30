module CPP-EXPR-UNARY
     imports FLOAT
     imports INT
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYMLOC-SYNTAX

     rule *(prv(Loc:SymLoc, Tr::Trace, T:CPPPointerType))
          => lv(Loc, combine(Tr, #klabel(`*__CPP-SYNTAX`)), innerType(T))

     rule &(lv(Loc:SymLoc, Tr::Trace, T::CPPType))
          => prv(Loc, combine(Tr, #klabel(`&__CPP-SYNTAX`)), type(pointerType(T)))

     rule getAddress(lv(Loc:SymLoc, Tr::Trace, T::CPPType))
          => prv(Loc, combine(Tr, #klabel(`&__CPP-SYNTAX`)), type(pointerType(T)))

     rule getAddress(xv(Loc:SymLoc, Tr::Trace, T::CPPType))
          => prv(Loc, combine(Tr, #klabel(`&__CPP-SYNTAX`)), type(pointerType(T)))

     rule getAddress(prv(Loc:SymLoc, Tr::Trace, T::CPPType))
          => prv(Loc, combine(Tr, #klabel(`&__CPP-SYNTAX`)), type(pointerType(T)))

     rule &(dataMemberValue(memberPointer(C::Class, X::CId, T::CPPType), Tr::Trace, _))
          => prv(memberPointer(C, X, T), Tr, t(noQuals, .Set, memberPointerType(t(noQuals, .Set, classType(C)),T)))

     context - (HOLE:Expr => reval(HOLE)) [result(EPRVal)]

     rule - prv(I:Int, Tr::Trace, T::CPPType)
          => arithInterpret(T, 0 -Int I, combine(Tr, #klabel(`-__CPP-SYNTAX`)))
          requires isPromoted(T)

     rule - prv(F:Float, Tr::Trace, T::CPPType)
          => arithInterpret(T, --Float F, combine(Tr, #klabel(`-__CPP-SYNTAX`)))
          requires isPromoted(T)

     context + (HOLE:Expr => reval(HOLE)) [result(EPRVal)]

     rule + prv(I:Int, Tr::Trace, T::CPPType)
          => arithInterpret(T, I, combine(Tr, #klabel(`+__CPP-SYNTAX`)))
          requires isPromoted(T)

     rule + prv(F:Float, Tr::Trace, T::CPPType)
          => arithInterpret(T, F, combine(Tr, #klabel(`+__CPP-SYNTAX`)))
          requires isPromoted(T)

endmodule
