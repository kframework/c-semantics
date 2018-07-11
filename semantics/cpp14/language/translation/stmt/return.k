module CPP-TRANSLATION-STMT-RETURN
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
     imports CPP-TRANSLATION-DECL-TEMPLATE-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION

     context TReturnOp(HOLE:Expr) [result(Val)]

     rule <k> ReturnStmt(I::Init) => TReturnOp(figureInit(le(temp(!I:Int, Ret), noTrace, Ret), Ret, I, CopyInit())) ...</k>
          <curr-function> Base::SymBase </curr-function>
          <functions>... Base |-> functionObject(_, t(_, _, functionType(... returnType: Ret::CPPType)), _, _) ...</functions>
          requires I =/=K NoInit()

     rule <k> ReturnStmt(I::Init) => .K ...</k>
          <elab>... .K => ReturnStmt(I) </elab>
          <curr-function> dependent </curr-function>
          requires I =/=K NoInit()

     rule ReturnStmt(NoInit()) => TReturnOp(prv(voidVal, noTrace, type(void)))

     rule <k> TReturnOp(V:Val) => .K ...</k>
          <elab>... .K => ReturnOp(V) </elab>

endmodule


