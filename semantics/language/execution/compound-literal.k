module C-COMPOUND-LITERAL
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-LITERAL-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports COMPAT-SYNTAX

     syntax CId ::= compoundLiteral(Int)
     syntax K ::= handleCompoundLiteral(K) [strict]
     
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
          
     rule <k> handleCompoundLiteral(initValue(X:CId, T:Type, Init:K))
               => allocObject(Base, T)
               ~> addToEnv(X, Base)
               ~> giveType(X, T)
               ~> allowInit(Init)
               ~> sequencePoint
               ~> X
          ...</k>
          <compound-lit-map> M:Map => M[Base <- X] </compound-lit-map>
          <next-loc> Base:SymBase => linc(Base) </next-loc>
          when notBool X in keys M
          [structural]

     // This and the compound-lit-map is apparently needed to properly handle
     // gotos. An instance (i.e., syntactic occurance) of a compound literal
     // apparently must always refer to the same object, even if it is
     // encountered multiple times (e.g., when in the body of a loop).
     rule <k> handleCompoundLiteral(initValue(X:CId, T:KResult, Init:K))
               => addToEnv(X, Base)
               ~> giveType(X, T)
               ~> allowInit(Init)
               ~> sequencePoint
               ~> X
          ...</k>
          <compound-lit-map>... X |-> Base:SymBase ...</compound-lit-map>
          [structural]
          
     // TODO(chathhorn) identical to trans, move these to common.
     rule <k> stringLiteral(S:String)
               => lv(lnew(string(S)),
                    t(.Set, arrayType(t(.Set, char), lengthString(S) +Int 1)))
          ...</k>
          <mem>... string(S) |-> _ ...</mem>
          [structural]
     rule <k> wstringLiteral(S:List)
               => lv(lnew(wstring(S)),
                    t(.Set, arrayType(cfg:wcharut, lengthList(S) +Int 1)))
          ...</k>
          <mem>... wstring(S) |-> _ ...</mem>
          [structural]

endmodule
