module CPP-EXPR-ADDITIVE
     imports BOOL
     imports FLOAT
     imports INT
     imports STRING
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (prv(Loc::SymLoc, Tr::Trace, t(... st: pointerType(...)) #as T::CPPType) + prv(I:Int, Tr'::Trace, cppIntegerType #as T'::CPPType)) #as O:Expr
          => addToPointer(Loc, T, I, combine(Tr, Tr', O))
          requires isCompleteType(innerType(T)) andBool isObjectType(innerType(T))

     rule (prv(I:Int, Tr::Trace, cppIntegerType #as T'::CPPType) + prv(Loc::SymLoc, Tr'::Trace, t(... st: pointerType(...)) #as T::CPPType)) #as O:Expr
          => addToPointer(Loc, T, I, combine(Tr, Tr', O))
          requires isCompleteType(innerType(T)) andBool isObjectType(innerType(T))

     syntax KItem ::= addToPointer(SymLoc, CPPType, Int, Trace) [klabel(addToPointerCPP)]

     rule addToPointer(Loc::SymLoc, T::CPPType, I::Int, Tr::Trace)
          => prv(newFromArray(Loc, T, I) +bytes (I *Int byteSizeofType(innerType(T))), Tr, T)
          requires ifFromArrayInBounds(Loc, T, I)

     rule (.K => UNDEF("CEA1",
               "A pointer (or array subscript) outside the bounds of an object."))
          ~> addToPointer(Loc::SymLoc, T::CPPType, I::Int, _)
          requires notBool ifFromArrayInBounds(Loc, T, I)

     syntax SymLoc ::= newFromArray(SymLoc, CPPType, Int) [function, klabel(newFromArrayCpp)]
                     | #newFromArray(SymLoc, K, Int) [function, klabel(#newFromArrayCpp)]

     rule newFromArray(Loc::SymLoc, T::CPPType, I::Int)
          => #newFromArray(Loc, getFromArray(Loc), byteSizeofType(innerType(T)) *Int I)

     rule #newFromArray(Loc::SymLoc, fromArray(ArrOffset::Int, Len::Int, Eff::EffectiveType), NewOffset::Int)
          => addProv(fromArray(ArrOffset +Int NewOffset, Len, Eff), stripFromArray(Loc))

     rule #newFromArray(Loc::SymLoc, .K, _) => Loc

     rule (prv(Loc::SymLoc, Tr::Trace, t(... st: pointerType(...)) #as T::CPPType) - prv(Loc'::SymLoc, Tr'::Trace, t(... st: pointerType(...)) #as T'::CPPType)) #as O:Expr
          => computePointerDifference(offset(Loc) -Int offset(Loc'), byteSizeofType(innerType(T)), type(ptrdiff_t), combine(Tr, Tr', O), "std::ptrdiff_t")
          requires sameBase(Loc, Loc')

     rule (.K => UNDEF("CEA2",
               "Computing pointer difference between two different objects."))
          ~> prv(Loc::SymLoc, _, t(... st: pointerType(...))) - prv(Loc'::SymLoc, _, t(... st: pointerType(...)))
          requires notBool sameBase(Loc, Loc')

     syntax KItem ::= computePointerDifference(Int, Int, CPPType, Trace, String) [klabel(computePointerDifferenceCPP)]

     rule computePointerDifference(Diff::Int, Size::Int, T::CPPType, Tr::Trace, _)
          => prv(Diff /Int Size, Tr, T)
          requires (Diff %Int Size ==Int 0)
               andBool inRange(Diff /Int Size, T)

     rule (.K => UNDEF("CEA3", "Pointer difference outside the range that can be represented by object of type " +String S +String "."))
          ~> computePointerDifference(Diff::Int, Size::Int, T::CPPType, _, S::String)
          requires notBool inRange(Diff /Int Size, T)

     rule (prv(I1:Int, Tr1::Trace, cppIntegerType #as T1::CPPType) + prv(I2:Int, Tr2::Trace, cppIntegerType #as T2::CPPType)) #as O:Expr
          => arithInterpret(T1, I1 +Int I2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule (prv(F1:Float, Tr1::Trace, t(... st: _:CPPSimpleFloatingType) #as T1::CPPType) + prv(F2:Float, Tr2::Trace, t(... st: _:CPPSimpleFloatingType) #as T2::CPPType)) #as O:Expr
          => arithInterpret(T1, F1 +Float F2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule (prv(I1:Int, Tr1::Trace, cppIntegerType #as T1::CPPType) - prv(I2:Int, Tr2::Trace, cppIntegerType #as T2::CPPType)) #as O:Expr
          => arithInterpret(T1, I1 -Int I2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule (prv(F1:Float, Tr1::Trace, t(... st: _:CPPSimpleFloatingType) #as T1::CPPType) - prv(F2:Float, Tr2::Trace, t(... st: _:CPPSimpleFloatingType) #as T2::CPPType)) #as O:Expr
          => arithInterpret(T1, F1 -Float F2, combine(Tr1, Tr2, O))
          requires isPromoted(T1) andBool T1 ==Type T2


     rule L:LVal [ R:Val ] => * (L + R)

     rule L:Val [ R:Val ] => * (L + R)
          requires isCPPPointerType(type(L))

endmodule
