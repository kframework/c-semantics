module CPP-STMT-RETURN
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION

     context ReturnOp(HOLE:Expr) [result(Val)]

     rule <k> ReturnStmt(I::Init) => ReturnOp(figureInit(le(temp(!I:Int, Ret), noTrace, Ret), Ret, AutoStorage, I)) ...</k>
          <curr-function> Base::SymBase </curr-function>
          <functions>... Base |-> functionObject(_, t(_, _, functionType(Ret::CPPType, _, _, _)), _, _) ...</functions>

     rule <k> ReturnOp(V:Val) => .K ...</k>
          <elab>... .K => ReturnOp(V) </elab>

endmodule


