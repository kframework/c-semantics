module CPP-EXECUTION-STMT-IF
     imports INT
     imports K-EQUAL
     imports BITS-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule IfStmt(prv((unknown(I::Int) => #if I ==Int 0 #then 0 #else 1 #fi), _, t(... st: _:CPPSimpleBoolType) #as T::CPPType), _, _)

     rule IfStmt(prv(1, _, t(... st: _:CPPSimpleBoolType) #as T::CPPType), S::Stmt, _) => fullExpression ~> S

     rule IfStmt(prv(0, _, t(... st: _:CPPSimpleBoolType) #as T::CPPType), _, S::Stmt) => fullExpression ~> S

endmodule
