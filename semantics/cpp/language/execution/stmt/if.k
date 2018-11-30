module CPP-EXECUTION-STMT-IF
     imports INT
     imports K-EQUAL
     imports BITS-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule IfStmt(prv((unknown(I::Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, T:CPPBoolType), _, _)

     rule IfStmt(prv(1, _, T:CPPBoolType), S::Stmt, _) => fullExpression ~> S

     rule IfStmt(prv(0, _, T:CPPBoolType), _, S::Stmt) => fullExpression ~> S

endmodule
