module CPP-COMMON-PROMOTION-CONTEXT-SYNTAX
     imports BASIC-K

     syntax Bool ::= isArithBinConversionOp(K) [function, klabelPredicate, klabel(isArithBinConversionOpCpp)]

endmodule

module CPP-COMMON-PROMOTION-CONTEXT
     imports CPP-COMMON-PROMOTION-CONTEXT-SYNTAX
     imports BOOL-SYNTAX
     imports CPP-SYNTAX

     rule isArithBinConversionOp(#klabel(`_+__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_-__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_*__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_/__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_%__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_^__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_&__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_|__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_!=__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_==__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_<__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_<=__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_>__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(#klabel(`_>=__CPP-SYNTAX`)) => true
     rule isArithBinConversionOp(_) => false [owise]

endmodule
