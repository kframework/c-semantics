module CPP-EXECUTION-EXPR-REFERENCE
     imports C-CONFIGURATION
     imports BOOL
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule bindReference(E1::Expr, E2::Expr)
          => bindReference2(E1, E2)
          requires Execution()

     syntax Expr ::= bindReference2(Expr, Expr) [strict(c; 2)]

     // we need this result tag because lvalues of reference type aren't KResults
     context bindReference2(HOLE:Expr, _) [result(LVal)]

     rule bindReference2(E1:LVal, E2::Expr)
          =>
          bindReference3(E1, E2) ~> referenceBindingResult(E1)

     syntax KItem ::= bindReference3(LVal, Expr) [strict(c; 2)]

     // @ref n4296 8.5.3:5.1.1
     // @ref n4800 9.3.3:5.1
     rule bindReference3(
               lv(... t: T1::CPPType) #as V1::LVal,
               lv(... t: T2::CPPType) #as V2::Expr
          )
          => bindReference4(V1, V2)
          requires isCPPLVRefType(T1)
          andBool notBool isCPPBitfieldType(T2)
          andBool isReferenceCompatible(innerType(T1), T2)

     // @ref n4800 9.3.3:5.3 - converted initializer is NOT a prvalue
     rule bindReference3(
               lv(... t: T1::CPPType) #as V1::LVal,
               xv(... t: T2::CPPType) #as V2::Expr
          )
          => bindReference4(V1, V2)
          requires notBool isCPPBitfieldType(T2)
          andBool isReferenceCompatible(innerType(T1), T2)
          andBool isValidReferenceType(T1)

     // @ref n4800 9.3.3:5.3 - converted initializer IS a prvalue
     rule <k>
          bindReference3(
               lv(... t: T1::CPPType) #as V1::LVal,
               prv(... t: T2::CPPType) #as V2::Expr
          )
          =>
          allocObject(
               bnew(!I:Int, innerType(T1), .Set, D),
               innerType(T1),
               byteSizeofType(innerType(T1))
          ) ~>
          bindReference4(
               V1,
               lv(lnew(bnew(!I:Int, innerType(T1), .Set, D)), noTrace, innerType(T1)) :=init V2
          )
          ...</k>
          <duration> D::Duration </duration>
          requires notBool isCPPClassType(T2)
          andBool notBool isCPPArrayType(T2)
          andBool notBool isCPPClassType(T1)

     syntax KItem ::= bindReference4(LVal, Expr) [strict(c; 2)]

     rule bindReference4(
               lv(Loc1::SymLoc, _, T1::CPPType),
               lv(Loc2::SymLoc, _, T2::CPPType)
          )
          =>
          bindReference5(Loc1, T1, Loc2, T2)

     rule bindReference4(
               lv(Loc1::SymLoc, _, T1::CPPType),
               xv(Loc2::SymLoc, _, T2::CPPType)
          )
          =>
          bindReference5(Loc1, T1, Loc2, T2)

     syntax KItem ::= bindReference5(SymLoc, CPPType, SymLoc, CPPType)

     rule <k>
          bindReference5(
               Loc1::SymLoc, T1::CPPType,
               Loc2::SymLoc, T2::CPPType
          )
          => .K
          ...</k>
          <references>...
          .Map => stripProv(Loc1) |-> referenceTarget(innerType(T1), Loc2, T2)
          ...</references>

     syntax SymLoc ::= referenceTarget(t1: CPPType, loc: SymLoc, t2: CPPType) [function]

     rule referenceTarget(t(... st: classType(...)) #as T1::CPPType, Loc::SymLoc, t(... st: classType(...)) #as T2::CPPType)
          => baseClassSubobject(Loc, T1, T2)
          requires isBaseClassOf(T1, T2)

     rule referenceTarget(... loc: Loc::SymLoc) => Loc [owise]

endmodule
