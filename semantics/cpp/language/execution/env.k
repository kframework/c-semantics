module CPP-EXECUTION-ENV-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-COMMON-ENV-SYNTAX

     syntax KItem ::= addToExecEnv(CId, CPPType, SymBase, Bool) [klabel(cppAddToExecEnv)]

     syntax KItem ::= addToHistory(Int) [klabel(cppAddToHistory)]

     syntax KItem ::= destructLocals(isException: Bool)
endmodule

module CPP-EXECUTION-ENV
     imports CPP-EXECUTION-ENV-SYNTAX
     imports C-CONFIGURATION

     rule <k> addToHistory(BlockNum:Int) => .K ...</k>
          <block-history> .List => ListItem(BlockNum) ...</block-history>

     rule <k> addToExecEnv(X::CId, T::CPPType, Base::SymBase, IsUsing::Bool)
              => .K
          ...</k>
          <env> E::Map => E[X, T <- envEntry(Base, IsUsing, NoDefArgs())] </env>

endmodule
