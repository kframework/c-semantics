module C-TRANSLATION-EXTENSIONS
  imports C-COMMON-EXTENSIONS

  syntax KItem ::= GnuBodyDone(Int)

  // Statement expressions
  rule `GnuBody`:KLabel(`Block`(BlockNum:Int, _, list(Stmts:List ListItem(CodeLoc(Computation(Stmt:K), Loc:K)))))
       => elaborate(listToK(Stmts ListItem(CodeLoc(GnuBodyReturn(Stmt), Loc)))) ~> GnuBodyDone(BlockNum)

  rule elaborateDone(K:K) ~> GnuBodyDone(BlockNum:Int) => te(pushBlock(BlockNum) ~> K ~> popBlock, gnuBodyType(K))

  rule <k> GnuBodyReturn(R:RValue) => .K ...</k>
       <elab>... .K => GnuBodyReturn(R) </elab>

  syntax Type ::= gnuBodyType(K) [function]

  rule gnuBodyType(K:KItem ~> K2:KItem ~> K3:K) => gnuBodyType(K2 ~> K3)
  rule gnuBodyType(GnuBodyReturn(R:RValue)) => type(R)

  // Typeof operator
  context `canonicalizeType-aux(_,_,_,_,_)`(_:List ListItem(`TypeofExpression`(HOLE:KItem)), _, _, _, _)

  rule `canonicalizeType-aux(_,_,_,_,_)`(_:List (ListItem(`TypeofExpression`(Result:Typed)) => .List), (.K => type(Result)), _, _, _)

endmodule
