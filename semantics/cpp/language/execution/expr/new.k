module CPP-EXECUTION-EXPR-NEW
     imports C-CONFIGURATION
     imports INT
     imports MEMORY-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-ENV-SYNTAX
     imports CPP-SETTINGS-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     context NewOp(_, _, _, (HOLE:Expr => reval(HOLE)), _) requires Execution() [result(PRV)]

     rule <k> NewOp(T::CPPType, Allocator::Expr, Init::Expr, prv(Size:Int, _, _), I::Int) => callAllocationFunction(T, Allocator, Init, Size, I) ...</k>
          <new-size-map>... .Map => I |-> Size ...</new-size-map>
          requires Execution() andBool Size >=Int 0 andBool Size <=Int cfg:maxNewSize

     rule NewOp(T::CPPType, Allocator::Expr, Init::Expr, .K, I::Int) => callAllocationFunction(T, Allocator, Init, I)
          requires Execution()

     syntax Expr ::= callAllocationFunction(CPPType, Expr, Expr, Int, Int) [klabel(callArrayAllocationFunction)]
                   | callAllocationFunction(CPPType, Expr, Expr, Int)

     context callAllocationFunction(_, (HOLE:Expr => reval(HOLE)), _, _, _) [result(PRV)]

     context callAllocationFunction(_, (HOLE:Expr => reval(HOLE)), _, _) [result(PRV)]

     rule <k> newSize(I::Int) => arithInterpret(type(size_t), Size, noTrace) ...</k>
          <new-size-map>... I |-> Size::Int ...</new-size-map>

     rule callAllocationFunction(T::CPPType, prv(Loc::SymLoc, _, _), Init::Expr, Size::Int, I::Int)
          => addToExecEnv(#NoName(I), type(arrayType(T, Size)), base(Loc), false)
          ~> setEffectiveType(base(Loc), type(arrayType(T, Size)))
          ~> makePRVal(Init)

     rule callAllocationFunction(T::CPPType, prv(Loc::SymLoc, _, _), Init::Expr, I::Int)
          => addToExecEnv(#NoName(I), T, base(Loc), false)
          ~> setEffectiveType(base(Loc), T)
          ~> & Init

     syntax KItem ::= setEffectiveType(SymBase, CPPType) [klabel(setEffectiveTypeCpp)]

     rule <k> setEffectiveType(Base::SymBase, T::CPPType) => .K ...</k>
          <mem>... Base |-> object((_ => T), _, _) ...</mem>

endmodule
