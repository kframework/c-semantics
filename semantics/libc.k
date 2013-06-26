require "libc/math.k"
require "libc/setjmp.k"
require "libc/stdarg.k"
require "libc/stddef.k"
require "libc/stdio.k"
require "libc/stdlib.k"
require "libc/string.k"
require "libc/threads.k"
require "libc/time.k"

module LIBC-SYNTAX
     syntax C ::= "vararg" "(" K ")" [hybrid, strict]
     syntax C ::= "nextvarg" "(" SymLoc "," K ")" [strict(2)] // loc, type
     syntax C ::= "vpair" "(" K "," K ")" [hybrid, strict]
     syntax K ::= "prepareBuiltin" "(" Id "," KList ")" 
     syntax K ::= incSymbolic(K)
     syntax K ::= "printString" "(" K ")"
endmodule

module LIBC-HELPERS
     imports COMMON-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS
     imports URIS
     imports C-CONFIGURATION

     imports LIBC-SYNTAX
     
     // TODO(chathhorn): not pretty
     rule rkludge(vararg(K:K)) => vararg(K) [structural, anywhere]

     // offset, type, length, checklength
     syntax C ::= "nextvarg-aux" "(" SymLoc "," Type "," K "," K ")"
     context nextvarg-aux(_, _, value(HOLE), _)
     context nextvarg-aux(_, _, _, value(HOLE))
     
     rule [nextvarg-start]:
          nextvarg(Loc:SymLoc, T:Type)
          => nextvarg-aux(Loc, T, 
               value(byteSizeofType(T)), value(sizeofLocation(Loc)))
          [structural]
     rule [nextvarg]:
          nextvarg-aux(Loc:SymLoc, T:Type, Len:Int, Len:Int)
          => vpair(read(Loc, T), 
               vararg(tv(linc(Loc), t(.Set, pointerType(t(.Set, void))))))
          [structural]
     
     context prepareBuiltin(_, (_,, (HOLE => reval(HOLE)),, _))
     
     syntax KList ::= idsFromDeclList(KList) [function]
     
     rule [idsFromDeclList-one]:
          idsFromDeclList((L:KList,, typedDeclaration(t(_, T:K), X:Id)))
          => idsFromDeclList(L:KList),, X:Id
          when T:K =/=K void
          [structural]
     rule [idsFromDeclList-void]:
          idsFromDeclList((L:KList,, typedDeclaration(t(_, void), _:Id)))
          => idsFromDeclList(L:KList)
          [structural]
     rule [idsFromDeclList-vararg]:
          idsFromDeclList((L:KList,, 
               typedDeclaration(T:KResult, X:Id),, t(_, variadic)))
          => idsFromDeclList((L:KList,, typedDeclaration(T:KResult, X:Id)))
               // assumes variadic args are placed in incremental blocks
               ,, vararg(incSymbolic(cast(t(.Set, 
               pointerType(t(.Set, unsigned-char))), &(X:Id))))
          [structural]
     rule [idsFromDeclList-done]:
          idsFromDeclList(.KList) => .KList [structural]

     context incSymbolic((HOLE => reval(HOLE)))
     rule [incSymbolic]:
          incSymbolic(tv(Loc:SymLoc, T:KResult)) => tv(linc(Loc), T:KResult)
          [structural]
          
     rule [prepareBuiltin]:
          handleBuiltin(F:Id, t(_, functionType(_:KResult, L:KList)))
          => Return(prepareBuiltin(F:Id, idsFromDeclList(L:KList)))
          [structural]
          
     rule printString(S:String)
          => writeToFD(1, asciiString(firstChar(S:String)))
               ~> printString(butFirstChar(S:String))
          when lengthString(S:String) >Int 0
          [structural]
     rule printString("") => writeToFD(1, 10)
          [structural]
endmodule

module LIBC
     ////////////////////////////////
     //- C standard library
     imports LIBC-HELPERS
     
     imports LIBC-MATH
     imports LIBC-SETJMP
     imports LIBC-STDARG
     imports LIBC-STDDEF
     imports LIBC-STDIO 
     imports LIBC-STDLIB
     imports LIBC-STRING
     imports LIBC-THREADS
     imports LIBC-TIME
endmodule
