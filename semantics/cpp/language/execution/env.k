module CPP-TRANSLATION-ENV-SYNTAX
     imports COMPAT-SORTS

      syntax DefaultArguments ::= defArgs(vals: StrictList, types: StrictList, cats: StrictList)

      syntax DefaultArguments ::= DefaultArgumentsResult

      syntax DefaultArgumentsResult ::= defArgs(vals: StrictListResult, types: StrictListResult, cats: StrictListResult)
endmodule

module CPP-EXECUTION-ENV-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYMLOC-SYNTAX

     syntax KItem ::= addToExecEnv(CId, CPPType, SymBase, Bool) [klabel(cppAddToExecEnv)]

     syntax KItem ::= addToHistory(Int) [klabel(cppAddToHistory)]

     syntax KItem ::= destructLocals(isException: Bool)
endmodule

module CPP-EXECUTION-ENV
     imports CPP-TRANSLATION-ENV-SYNTAX
     imports CPP-EXECUTION-ENV-SYNTAX
     imports C-CONFIGURATION

     rule <k> addToHistory(BlockNum:Int) => .K ...</k>
          <block-history> .List => ListItem(BlockNum) ...</block-history>

     rule <k> addToExecEnv(X::CId, T::CPPType, Base::SymBase, IsUsing::Bool)
              => .K
          ...</k>
          <env> E::Map => E[X, T <- envEntry(Base, IsUsing, NoDefArgs())] </env>

endmodule
