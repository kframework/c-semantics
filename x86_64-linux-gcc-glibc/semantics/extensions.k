module C-COMMON-EXTENSIONS
  imports C-SYNTAX
  imports COMPAT-SYNTAX
  imports C-DYNAMIC-SYNTAX
  imports C-TYPING-STRICTNESS-SYNTAX
  imports C-TYPING-CANONICALIZATION-SYNTAX

  // Statement expressions
  syntax KItem ::= GnuBodyReturn(K)
  context GnuBodyReturn(HOLE => reval(HOLE)) [result(RValue)]

  rule <type> GnuBody(Block(_, _, list(_ ListItem(CodeLoc(Computation(K:K), _))))) => K ...</type>

  rule <k> GnuBody(Block(BlockNum:Int, K:K, list(Stmts:List ListItem(CodeLoc(Computation(Stmt:K), Loc:K)))))
           => BlockStatement(Block(BlockNum, K, list(Stmts ListItem(CodeLoc(GnuBodyReturn(Stmt), Loc))))) ...</k>

  rule GnuBodyReturn(R:RValue) ~> popBlock => popBlock ~> R

  // Typeof operator
  rule <k> canonicalizeType-aux(_:List ListItem(TypeofExpression(K:K) => evalToType), _, _, _, _) ...</k>
       (.Bag => <type> K:K </type>)

  rule <k> canonicalizeType-aux(_:List (ListItem(evalToType) => .List), (.K => T), _, _, _) ...</k>
       (<type> T:Type </type> => .Bag)
endmodule

module C-EXECUTION-EXTENSIONS
  imports C-COMMON-EXTENSIONS
  imports C-CHECK-LOC-SYNTAX

  rule GnuBodyReturn(R:RValue) ~> exitRestrictScope(Tag:RestrictTag) ~> popBlock => exitRestrictScope(Tag) ~> popBlock ~> R

endmodule
