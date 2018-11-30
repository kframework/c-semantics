module CPP-COMMON-PROMOTION-CONTEXT-SYNTAX
     imports BASIC-K

     syntax Bool ::= isArithBinConversionOp(K) [function, klabelPredicate, klabel(isArithBinConversionOpCpp)]
                   | isCompositePointerOp(K) [function, klabelPredicate]
                   | isPromoteOp(K) [function, klabelPredicate]

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

     rule isCompositePointerOp(#klabel(`_!=__CPP-SYNTAX`)) => true

     rule isCompositePointerOp(#klabel(`_==__CPP-SYNTAX`)) => true

     rule isCompositePointerOp(#klabel(`_<__CPP-SYNTAX`)) => true

     rule isCompositePointerOp(#klabel(`_<=__CPP-SYNTAX`)) => true

     rule isCompositePointerOp(#klabel(`_>__CPP-SYNTAX`)) => true

     rule isCompositePointerOp(#klabel(`_>=__CPP-SYNTAX`)) => true

     rule isCompositePointerOp(_) => false [owise]

     rule isPromoteOp(#klabel(`-__CPP-SYNTAX`)) => true

     rule isPromoteOp(#klabel(`+__CPP-SYNTAX`)) => true

     rule isPromoteOp(#klabel(`~__CPP-SYNTAX`)) => true

     rule isPromoteOp(#klabel(`_<<__CPP-SYNTAX`)) => true

     rule isPromoteOp(#klabel(`_>>__CPP-SYNTAX`)) => true

     rule isPromoteOp(_) => false [owise]

endmodule
