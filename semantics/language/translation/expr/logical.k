module C-EXPR-LOGICAL
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     context _ && (HOLE => reval(HOLE)) [result(RValue)]
     rule e(L:K, _) && e(R:K, _) => e(L && R, t(.Set, int))
     rule e(L:K, _) && tv(V:CValue, T:Type) => e(L && tv(V, T), t(.Set, int))

     context _ || (HOLE => reval(HOLE)) [result(RValue)]
     rule e(L:K, _) || e(R:K, _) => e(L || R, t(.Set, int))
     rule e(L:K, _) || tv(V:CValue, T:Type) => e(L || tv(V, T), t(.Set, int))

endmodule
