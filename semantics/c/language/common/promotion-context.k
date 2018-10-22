module C-COMMON-PROMOTION-CONTEXT-SYNTAX
     imports BASIC-K

     syntax Bool ::= isArithBinConversionOp(K) [function, klabelPredicate]
     syntax Bool ::= isArithBinOp(K) [function, klabelPredicate]
     syntax Bool ::= isArithBinNonEqualityOp(K) [function, klabelPredicate]
     syntax Bool ::= isArithUnaryOp(K) [function, klabelPredicate]

endmodule

module C-COMMON-PROMOTION-CONTEXT
     imports C-COMMON-PROMOTION-CONTEXT-SYNTAX
     imports BOOL-SYNTAX
     imports C-SYNTAX

     rule isArithBinNonEqualityOp(#klabel(`_*__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_/__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_%__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_+__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_-__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_<__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_>__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_<=__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_>=__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_&__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_|__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_^__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_<<__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(#klabel(`_>>__C-SYNTAX`)) => true
     rule isArithBinNonEqualityOp(_) => false [owise]



     rule isArithBinOp(#klabel(`_*__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_/__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_%__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_+__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_-__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_<__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_>__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_<=__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_>=__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_==__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_!=__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_&__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_|__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_^__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_<<__C-SYNTAX`)) => true
     rule isArithBinOp(#klabel(`_>>__C-SYNTAX`)) => true
     rule isArithBinOp(_) => false [owise]

     rule isArithBinConversionOp(#klabel(`_*__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_/__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_%__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_+__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_-__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_<__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_>__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_<=__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_>=__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_==__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_!=__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_&__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_|__C-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_^__C-SYNTAX`)) => true
     rule isArithBinConversionOp(_) => false [owise]

     rule isArithUnaryOp(#klabel(`-__C-SYNTAX`)) => true
     rule isArithUnaryOp(#klabel(`+__C-SYNTAX`)) => true
     rule isArithUnaryOp(#klabel(`~__C-SYNTAX`)) => true
     rule isArithUnaryOp(_) => false [owise]


endmodule
