module CPP-EXPR-RELATIONAL
     imports INT
     imports FLOAT
     imports CPP-SYMLOC-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax PRVal ::= makeTruth(Bool, Trace) [function, klabel(makeTruthCpp)]

     rule makeTruth(B:Bool, Tr::Trace)
          => #if B #then prv(1, Tr, type(bool)) #else prv(0, Tr, type(bool)) #fi

     rule (prv(I1:Int, Tr1::Trace, T1::CPPType) == prv(I2:Int, Tr2::Trace, T2::CPPType)) #as O:Expr
          => makeTruth(I1 ==Int I2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule (prv(F1:Float, Tr1::Trace, T1::CPPType) == prv(F2:Float, Tr2::Trace, T2::CPPType)) #as O:Expr
          => makeTruth(F1 ==Float F2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule (prv(Loc1:SymLoc, Tr1::Trace, T1::CPPType) == prv(Loc2:SymLoc, Tr2::Trace, T2::CPPType)) #as O:Expr
          => makeTruth(sameAddress(Loc1, Loc2), combine(Tr1, Tr2, O))
          requires isCompositePointerType(T1) andBool T1 ==Type T2

     // @ref n4296 5.10:3.1-3.2
     rule (prv(NullMemberFunctionPointer, Tr1::Trace, t(... st: memberPointerType(_, t(... st: functionType(...)))) #as T1::CPPType) == prv(P:MemberFunctionPtr, Tr2::Trace, t(... st: memberPointerType(_, t(... st: functionType(...)))) #as T2::CPPType)) #as O:Expr
          => makeTruth(P ==K NullMemberFunctionPointer, combine(Tr1, Tr2, O))
          requires isCompositePointerType(T1) andBool  T1 ==Type T2

     rule (prv(P:MemberFunctionPtr, Tr1::Trace, t(... st: memberPointerType(_, t(... st: functionType(...)))) #as T1::CPPType) == prv(NullMemberFunctionPointer, Tr2::Trace, t(... st: memberPointerType(_, t(... st: functionType(...)))) #as T2::CPPType)) #as O:Expr
          => makeTruth(P ==K NullMemberFunctionPointer, combine(Tr1, Tr2, O))
          requires isCompositePointerType(T1) andBool T1 ==Type T2

     rule (prv(NullMemberPointer, Tr1::Trace, t(... st: memberPointerType(...)) #as T1::CPPType) == prv(P:MemberPtr, Tr2::Trace, t(... st: memberPointerType(...)) #as T2::CPPType)) #as O:Expr
          => makeTruth(P ==K NullMemberPointer, combine(Tr1, Tr2, O))
          requires isCompositePointerType(T1) andBool  T1 ==Type T2

     rule (prv(P:MemberPtr, Tr1::Trace, t(... st: memberPointerType(...)) #as T1::CPPType) == prv(NullMemberPointer, Tr2::Trace, t(... st: memberPointerType(...)) #as T2::CPPType)) #as O:Expr
          => makeTruth(P ==K NullMemberPointer, combine(Tr1, Tr2, O))
          requires isCompositePointerType(T1) andBool T1 ==Type T2

     rule (prv(I1:Int, Tr1::Trace, T1::CPPType) != prv(I2:Int, Tr2::Trace, T2::CPPType)) #as O:Expr
          => makeTruth(I1 =/=Int I2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule (prv(F1:Float, Tr1::Trace, T1::CPPType) != prv(F2:Float, Tr2::Trace, T2::CPPType)) #as O:Expr
          => makeTruth(F1 =/=Float F2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule (prv(Loc1:SymLoc, Tr1::Trace, T1::CPPType) != prv(Loc2:SymLoc, Tr2::Trace, T2::CPPType)) #as O:Expr
          => makeTruth(notBool sameAddress(Loc1, Loc2), combine(Tr1, Tr2, O))
          requires isCompositePointerType(T1) andBool T1 ==Type T2

     // @ref n4296 5.10:3.1-3.2
     rule (prv(NullMemberFunctionPointer, Tr1::Trace, t(... st: memberPointerType(_, t(... st: functionType(...)))) #as T1::CPPType) != prv(P:MemberFunctionPtr, Tr2::Trace, t(... st: memberPointerType(_, t(... st: functionType(...)))) #as T2::CPPType)) #as O:Expr
          => makeTruth(P =/=K NullMemberFunctionPointer, combine(Tr1, Tr2, O))
          requires isCompositePointerType(T1) andBool T1 ==Type T2

     rule (prv(P:MemberFunctionPtr, Tr1::Trace, t(... st: memberPointerType(_, t(... st: functionType(...)))) #as T1::CPPType) != prv(NullMemberFunctionPointer, Tr2::Trace, t(... st: memberPointerType(_, t(... st: functionType(...)))) #as T2::CPPType)) #as O:Expr
          => makeTruth(P =/=K NullMemberFunctionPointer, combine(Tr1, Tr2, O))
          requires isCompositePointerType(T1) andBool T1 ==Type T2

     rule (prv(NullMemberPointer, Tr1::Trace, t(... st: memberPointerType(...)) #as T1::CPPType) != prv(P:MemberPtr, Tr2::Trace, t(... st: memberPointerType(...)) #as T2::CPPType)) #as O:Expr
          => makeTruth(P =/=K NullMemberPointer, combine(Tr1, Tr2, O))
          requires isCompositePointerType(T1) andBool T1 ==Type T2

     rule (prv(P:MemberPtr, Tr1::Trace, t(... st: memberPointerType(...)) #as T1::CPPType) != prv(NullMemberPointer, Tr2::Trace, t(... st: memberPointerType(...)) #as T2::CPPType)) #as O:Expr
          => makeTruth(P =/=K NullMemberPointer, combine(Tr1, Tr2, O))
          requires isCompositePointerType(T1) andBool T1 ==Type T2

     rule (prv(I1:Int, Tr1::Trace, T1::CPPType) < prv(I2:Int, Tr2::Trace, T2::CPPType)) #as O:Expr
          => makeTruth(I1 <Int I2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule (prv(I1:Int, Tr1::Trace, T1::CPPType) > prv(I2:Int, Tr2::Trace, T2::CPPType)) #as O:Expr
          => makeTruth(I1 >Int I2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule (prv(I1:Int, Tr1::Trace, T1::CPPType) <= prv(I2:Int, Tr2::Trace, T2::CPPType)) #as O:Expr
          => makeTruth(I1 <=Int I2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule (prv(I1:Int, Tr1::Trace, T1::CPPType) >= prv(I2:Int, Tr2::Trace, T2::CPPType)) #as O:Expr
          => makeTruth(I1 >=Int I2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2

endmodule
