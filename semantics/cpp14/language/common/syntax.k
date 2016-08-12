module CPP-SORTS
     syntax CId ::= OpId
     syntax CId ::= TempId
     syntax Init ::= Stmt | Expr
     syntax Expr ::= Name
     syntax Name
     syntax Stmt
     syntax OpId
     syntax TempId
     syntax Tag
endmodule

module CPP-SYNTAX
     imports CPP-SORTS
     imports INT-SYNTAX
     imports LIST
     imports CPP-DYNAMIC-SORTS
     imports CPP-REVAL-SYNTAX

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
                   

     syntax TempId ::= arg(Int)
                     | "ret"

     syntax CId ::= Destructor(CId)

     syntax ClassKey ::= Struct() | Union() | Class() 
     syntax Tag ::= ClassKey | Enum() | Typename() | NoTag()

     syntax Expr ::= Expr ":=" Init [strict(1)]
                   | "*" Expr
                   | "&" Expr
                   | BuiltinCallOp(Expr, Int, K)
     syntax Name ::= Name(NNS, CId)
                   | Name(NNS, CId, List)

     context _ := (HOLE:Expr => reval(HOLE)) [result(PRVal)]
     context * (HOLE:Expr => reval(HOLE)) [result(PRVal)]

     syntax Stmt ::= BlockStmt(Int, List)
                   | LabelStmt(CId, List)
                   | GotoStmt(CId)
                   | ExpressionStmt(Expr) [strict]
                   | ReturnOp(K)

endmodule
