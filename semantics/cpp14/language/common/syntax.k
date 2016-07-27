module CPP-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     syntax OpId ::= "operatornew"
                   | "operatordelete"
                   | "operatornew[]"
                   | "operatordelete[]"
                   | "operator+"
                   | "operator-"
                   | "operator*"
                   | "operator/"
                   | "operator%"
                   | "operator^"
                   | "operator&"
                   | "operator|"
                   | "operator~"
                   | "operator!"
                   | "operator="
                   | "operator<"
                   | "operator>"
                   | "operator+="
                   | "operator-="
                   | "operator*="
                   | "operator/="
                   | "operator%="
                   | "operator^="
                   | "operator&="
                   | "operator|="
                   | "operator<<"
                   | "operator>>"
                   | "operator<<="
                   | "operator>>="
                   | "operator=="
                   | "operator!="
                   | "operator<="
                   | "operator>="
                   | "operator&&"
                   | "operator||"
                   | "operator++"
                   | "operator--"
                   | "operator,"
                   | "operator->*"
                   | "operator->"
                   | "operator()"
                   | "operator[]"

     // not technically operator ids, but used internally in order to process
     // syntax from the parser
     syntax OpId ::= "operator."
                   | "operator.*"
                   | "operator?"
                   | "operator_++"
                   | "operator++_"
                   | "operator_--"
                   | "operator--_"
                   
     syntax CId ::= OpId

     syntax TempId ::= arg(Int)
                     | "ret"
     syntax CId ::= TempId

     syntax CId ::= Destructor(CId)

     syntax Init ::= Stmt | Expr

     syntax Expr ::= Expr ":=" Init [strict(1)]
                   | "*" Expr
                   | Name
                   | BuiltinCallOp(Expr, Int, K)
     syntax Name ::= Name(NNS, CId)

     context _ := (HOLE:Expr => reval(HOLE)) [result(PRVal)]
     context * (HOLE:Expr => reval(HOLE)) [result(PRVal)]

     syntax Stmt ::= BlockStmt(Int, List)
                   | LabelStmt(CId, List)
                   | GotoStmt(CId)
                   | ExpressionStmt(Expr) [strict]
                   | ReturnOp(K)

endmodule
