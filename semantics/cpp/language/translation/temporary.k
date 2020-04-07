module CPP-TRANSLATION-TEMPORARY-SYNTAX
     imports DOMAINS-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax Expr ::= CreateTemporary
     syntax KItem
     syntax CreateTemporary ::= createTemporary(temporary: Expr, type: CPPType, init: KItem) [strict(3)]
endmodule

module CPP-TRANSLATION-TEMPORARY
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
     imports CPP-TRANSLATION-TEMPORARY-SYNTAX

     rule createTemporary(Tmp::Expr, T::CPPType, Init:Expr)
          => le(createTemporaryExec(Tmp, Init), noTrace, T)
          requires isKResult(Init)

     rule createTemporary(_, _, ill-formed) => ill-formed

endmodule
