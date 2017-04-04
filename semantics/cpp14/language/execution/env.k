module CPP-ENV-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports SYMLOC-SYNTAX

     syntax KItem ::= addToEnv(CId, CPPType, SymBase, Bool) [klabel(cppAddToEnv)]
     syntax KItem ::= addToHistory(Int) [klabel(cppAddToHistory)]

     syntax KItem ::= destructLocals(isException: Bool)
endmodule

module CPP-ENV
     imports CPP-ENV-SYNTAX
     imports C-CONFIGURATION

     rule <k> addToHistory(BlockNum:Int) => .K ...</k>
          <block-history> .List => ListItem(BlockNum) ...</block-history>

     rule <k> addToEnv(X::CId, T::CPPType, Base::SymBase, IsUsing::Bool)
              => .K
          ...</k>
          <env> E::Map => E[X, T <- kpair(IsUsing, Base)] </env>

endmodule
