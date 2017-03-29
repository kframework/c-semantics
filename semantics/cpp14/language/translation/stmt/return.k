module CPP-STMT-RETURN
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION

     context ReturnOp(HOLE:Expr) [result(Val)]

     rule <k> ReturnStmt(I::Init) => ReturnOp(figureInit(le(temp(!I:Int, Ret), noTrace, Ret), Ret, I, CopyInit())) ...</k>
          <curr-function> Base::SymBase </curr-function>
          <functions>... Base |-> functionObject(_, t(_, _, functionType(... returnType: Ret::CPPType)), _, _) ...</functions>
          requires I =/=K NoInit()

     rule <k> ReturnStmt(NoInit()) => ReturnOp(prv(voidVal, noTrace, type(void))) ...</k>
          <curr-scope> blockScope(_ :: X::CId, _, _) </curr-scope>
          requires notBool isDestructorId(X)

     // 12.4:8
     rule <k> ReturnStmt(NoInit()) => GotoStmt(destructorLabel(X)) ...</k>
          <curr-scope> blockScope(_ :: DestructorId(_) #as X::CId, _, _) </curr-scope>

     rule <k> ReturnOp(V:Val) => .K ...</k>
          <elab>... .K => ReturnOp(V) </elab>

endmodule


