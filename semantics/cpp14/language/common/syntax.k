module CPP-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     syntax OpId ::= "operator()"
     syntax CId ::= OpId

     syntax CId ::= arg(Int)
                  | "ret"

     syntax Init ::= Stmt | Expr

     syntax Expr ::= Expr ":=" Init [strict(1)]
                   | Name(Namespace, CId)
                   | BuiltinCallOp(Expr, K)

     context _ := (HOLE:Expr => reval(HOLE)) [result(PRVal)]

     syntax Stmt ::= CompoundStmt(List)
                   | BlockStmt(Int, List)
                   | LabelStmt(CId, List)
                   | GotoStmt(CId)
                   | ExpressionStmt(Expr) [strict]
                   | ReturnOp(K)

endmodule
