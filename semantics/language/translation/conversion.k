module C-TRANSLATION-CONVERSION
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule cast(t(S:Set, structType(X:CId, NBits:Int, Info:FieldInfo)),
               tv(V:CValue, t(S, incompleteStructType(X))))
          => tv(V, t(S, structType(X, NBits, Info)))
endmodule
