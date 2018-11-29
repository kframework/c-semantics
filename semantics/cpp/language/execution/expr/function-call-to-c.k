module C-CPP-EXECUTION-EXPR-FUNCTION-CALL
     imports FUNCTION-CALL-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports BITS-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-CHECK-RESTRICT-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-SYNTAX
     imports CPP-BINDING-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-ENV-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-MEMORY-READING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports C-DYNAMIC-SYNTAX


     // Function call conversion (C linkage)
     rule application(_, _, functionObject(X::CId, _, _),
               (T:CPPFunctionType => convertTypeToC(T)), _, krlist(L::List => mapList(L, #klabel(`convertValToC`))))

     syntax RValue ::= convertValToC(PRVal) [function]

     rule convertValToC(prv(V::CPPValue, _, T::CPPType)) => tv({V}:>CValue, utype(convertTypeToC(T)))
          requires isCValue(V)

endmodule
