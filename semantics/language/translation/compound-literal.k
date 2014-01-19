module C-COMPOUND-LITERAL
     imports C-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX

     syntax Id ::= compoundLiteral(Int)
     syntax K ::= handleCompoundLiteral(K) [strict]

     // Compound literals at file scope get stored in global memory (i.e., the
     // data segment). At function scope, though, they have automatic storage
     // class. This is different from how string literals are treated.
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.2.5}{3--7}}}{
     A postfix expression that consists of a parenthesized type name followed
     by a brace-enclosed list of initializers is a \emph{compound literal}. It
     provides an unnamed object whose value is given by the initializer list.
     
     If the type name specifies an array of unknown size, the size is
     determined by the initializer list as specified in 6.7.9, and the type of
     the compound literal is that of the completed array type. Otherwise (when
     the type name specifies an object type), the type of the compound literal
     is that specified by the type name. In either case, the result is an
     lvalue.
     
     The value of the compound literal is that of an unnamed object initialized
     by the initializer list. If the compound literal occurs outside the body
     of a function, the object has static storage duration; otherwise, it has
     automatic storage duration associated with the enclosing block.
     
     All the semantic rules for initializer lists in 6.7.9 also apply to
     compound literals.
     
     String literals, and compound literals with const-qualified types, need
     not designate distinct objects.
     }*/
     
     /*@ We use \kinline{compoundLiteral(N:Int)} here as the identifier of the
     compound literal.*/
     // comes back from figureInit as initValue(id, type, inits)
     rule CompoundLiteral(N:Int, T:Type, K:K, Init:K)
          => handleCompoundLiteral(
               figureInit(compoundLiteral(N), DeclType(T, K), Init))
          [structural]
          
     rule <k> 
               handleCompoundLiteral(initValue(X:Id, T:Type, Init:K))
               => allocateType(Loc, T)
               ~> addToEnv(X, Loc)
               ~> giveType(X, T)
               ~> zero(X)
               ~> Init
               ~> X
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <currentFunction> file-scope </currentFunction>
          [structural]

     rule <k> 
               handleCompoundLiteral(initValue(X:Id, T:Type, _))
               => giveType(X, T)
               ~> X
          ...</k>
          <currentFunction> F:Id </currentFunction>
          when F =/=K file-scope
          [structural]
          
endmodule
