module CPP-STMT-RETURN
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION

     rule <k> ReturnStmt(I::Init) => returnHelper(figureInit(le(Name(NoNNS(), ret), noTrace, Ret), Ret, AutoStorage, I, I)) ...</k>
          <curr-function> Base::SymBase </curr-function>
          <functions>... Base |-> functionObject(_, t(_, _, functionType(Ret::CPPType, _, _)), _, _) ...</functions>

     syntax KItem ::= returnHelper(K) [strict]

     rule <k> returnHelper(initValue(_, _, K:K)) => ReturnOp(K) ...</k>

     rule <k> ReturnOp(K:K) => .K ...</k>
          <elab>... .K => ReturnOp(K) </elab>

endmodule


