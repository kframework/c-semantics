module LIBCPP-EXCEPTION
     imports LIBCPP-BOOTSTRAP-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-MEMORY-ALLOC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     // terminate_handler has c++ linkage so we need to wrap the call to abort in a c++ linkage function
     rule builtin(GlobalNamespace() :: Identifier("__cpp_abort"))
          => BuiltinCallOp(lv(lnew(obj(0, 0, builtinSymbol("abort"))), noTrace, func(type(void), CLinkage)), .List)

     rule builtin(GlobalNamespace() :: Namespace(Identifier("std")) :: Identifier("terminate")) 
          => BuiltinCallOp(lv(lnew(bnew(0, terminate_handler, .Set, builtinSymbol("::std::__terminate_handler"))), noTrace, terminate_handler), .List)

     syntax CPPType ::= "terminate_handler" [function]
     rule terminate_handler => ptr(func(type(void)))

     rule initException
          => allocObject(bnew(0, terminate_handler, .Set, builtinSymbol("::std::__terminate_handler")), terminate_handler, byteSizeofType(terminate_handler))
          ~> allowInit(ExpressionStmt(lv(lnew(bnew(0, terminate_handler, .Set, builtinSymbol("::std::__terminate_handler"))), noTrace, terminate_handler) := prv(lnew(obj(0, 0, builtinSymbol("::__cpp_abort()"))), noTrace, terminate_handler)))

endmodule
