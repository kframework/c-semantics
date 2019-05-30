module CPP-EXPR-UNARY
     imports FLOAT
     imports INT
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports C-CONFIGURATION

     rule (*(prv(Loc:SymLoc, Tr::Trace, t(... st: pointerType(...)) #as T::CPPType))) #as O:Expr
          => lv(Loc, combine(Tr, O), innerType(T))

     rule (&(lv(Loc:SymLoc, Tr::Trace, T::CPPType))) #as O:Expr
          => prv(Loc, combine(Tr, O), type(pointerType(T)))

     rule getAddress(lv(Loc:SymLoc, Tr::Trace, T::CPPType) #as O:LVal)
          => prv(Loc, combine(Tr, & O), type(pointerType(T)))

     rule getAddress(xv(Loc:SymLoc, Tr::Trace, T::CPPType) #as O:XVal)
          => prv(Loc, combine(Tr, & O), type(pointerType(T)))

     rule getAddress(prv(Loc:SymLoc, Tr::Trace, T::CPPType) #as O:PRVal)
          => prv(Loc, combine(Tr, & O), type(pointerType(T)))

     rule &(dataMemberValue(memberPointer(C::Class, X::CId, T::CPPType), Tr::Trace, _))
          => prv(memberPointer(C, X, T), Tr, t(noQuals, .Set, memberPointerType(t(noQuals, .Set, classType(C)),T)))

     context <k> - (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> - (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     rule (- prv(I:Int, Tr::Trace, T::CPPType)) #as O:Expr
          => arithInterpret(T, 0 -Int I, combine(Tr, O))
          requires isPromoted(T)

     rule (- prv(F:Float, Tr::Trace, T::CPPType)) #as O:Expr
          => arithInterpret(T, --Float F, combine(Tr, O))
          requires isPromoted(T)

     context <k> + (HOLE:Expr => reval(HOLE)) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> + (HOLE:Expr => reval(HOLE)) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     rule (+ prv(I:Int, Tr::Trace, T::CPPType)) #as O:Expr
          => arithInterpret(T, I, combine(Tr, O))
          requires isPromoted(T)

     rule (+ prv(F:Float, Tr::Trace, T::CPPType)) #as O:Expr
          => arithInterpret(T, F, combine(Tr, O))
          requires isPromoted(T)

endmodule
