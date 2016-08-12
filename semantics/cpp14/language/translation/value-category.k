module CPP-VALUE-CATEGORY-SYNTAX
    imports CPP-DYNAMIC-SORTS
    syntax Bool ::= isExprLValue(Expr) [function]
                  | isExprXValue(Expr) [function]
                  | isExprPRValue(Expr) [function]

endmodule

module CPP-VALUE-CATEGORY
     imports CPP-VALUE-CATEGORY-SYNTAX
     imports BOOL-SYNTAX
     imports CPP-ABSTRACT-SYNTAX

     rule isExprLValue(_) => false [owise]
     rule isExprXValue(_) => false [owise]
     rule isExprPRValue(_) => false [owise]

     rule isExprPRValue(NullPointerLiteral()) => true

endmodule
