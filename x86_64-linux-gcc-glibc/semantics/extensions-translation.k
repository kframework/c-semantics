module C-TRANSLATION-EXTENSIONS
  imports C-COMMON-EXTENSIONS
  imports C-ABSTRACT-SYNTAX
  imports C-TYPING-EXPR-SYNTAX
  imports C-TYPING-CANONICALIZATION-SYNTAX

  syntax KItem ::= GnuBodyDone(Int)

  // Statement expressions
  rule GnuBody(Block(BlockNum:Int, _, list(Stmts:List ListItem(CodeLoc(Computation(Stmt:K), Loc::CabsLoc)))))
       => elaborate(listToK(Stmts ListItem(CodeLoc(GnuBodyReturn(Stmt), Loc)))) ~> GnuBodyDone(BlockNum)

  rule elaborateDone(K:K) ~> GnuBodyDone(BlockNum:Int) => te(pushBlock(BlockNum) ~> K ~> popBlock, gnuBodyType(K))

  rule <k> GnuBodyReturn(R:RValue) => .K ...</k>
       <elab>... .K => GnuBodyReturn(R) </elab>

  syntax Type ::= gnuBodyType(K) [function]

  rule gnuBodyType(K:KItem ~> K2:KItem ~> K3:K) => gnuBodyType(K2 ~> K3)
  rule gnuBodyType(GnuBodyReturn(R:RValue)) => type(R)

  // Typeof operator
  context canonicalizeType-aux(_:List ListItem(`TypeofExpression`(HOLE:KItem => typeof(HOLE))), _, _, _, _) [result(Type)]

  rule canonicalizeType-aux(_:List (ListItem(`TypeofExpression`(Result:Type)) => .List), (.K => Result), _, _, _)

  rule typeof(GnuBody(Block(_, _, list(Stmts:List ListItem(CodeLoc(Computation(Stmt:K), _))))) => Stmt)

endmodule
