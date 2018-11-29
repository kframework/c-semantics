module CPP-TRANSLATION-STMT-BLOCK
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports CPP-TRANSLATION-ENV-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX

     syntax KItem ::= TpushBlock(Int)
                    | "TpopBlock"

     rule toExecution(TpushBlock(Tag::Int)) => pushBlock(Tag)

     rule toExecution(TpopBlock) => popBlock

     rule <k> TpushBlock(Tag::Int) #as It:KItem => elaborateThen(It) ~> pushLocals ...</k>
          <curr-tr-scope> blockScope(_, _, (_ => Tag)) </curr-tr-scope>
          <tr-block-history> .List => ListItem(Tag) ...</tr-block-history>

     rule <k> TpopBlock #as It:KItem => elaborateThen(It) ~> popLocals ~> setScope(blockScope(F, Base, Tag)) ...</k>
          <curr-tr-scope> blockScope(F::QualId, Base::SymBase, _) </curr-tr-scope>
          <tr-block-history> (ListItem(_) => .List) ListItem(Tag::Int) ...</tr-block-history>

     rule <k> TpopBlock #as It:KItem => elaborateThen(It) ~> popLocals ~> setScope(blockScope(F, Base, 0)) ...</k>
          <curr-tr-scope> blockScope(F::QualId, Base::SymBase, _) </curr-tr-scope>
          <tr-block-history> (ListItem(_) => .List) </tr-block-history>

     rule BlockStmt(Tag::Int, L::List) => TpushBlock(Tag) ~> listToK(L) ~> TpopBlock

endmodule
