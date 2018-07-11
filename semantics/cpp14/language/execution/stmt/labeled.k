module CPP-EXECUTION-STMT-LABELED
     imports COMPAT-SYNTAX
     imports CPP-SYNTAX

     rule LabelStmt(_, L::List) => listToK(L)

endmodule
