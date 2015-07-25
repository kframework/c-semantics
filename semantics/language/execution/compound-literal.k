module C-COMPOUND-LITERAL
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

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
     rule <k> initCompoundLiteral(initValue(X:CId, T:Type, Init:K))
               => initCompoundLiteralHelper(initValue(X, T, Init), !I:Int @ D)
          ...</k>
          <compound-lit-map> M:Map </compound-lit-map>
          <duration> D:Duration </duration>
          requires notBool (X in_keys(M))
          [structural]
     rule <k> initCompoundLiteral(initValue(X:CId, T:Type, Init:K))
               => initCompoundLiteralHelper(initValue(X, T, Init), !I:Int @ D)
          ...</k>
          <compound-lit-map>... X |-> Base:SymBase ...</compound-lit-map>
          <local-addresses> Addrs:Set </local-addresses>
          <duration> D:Duration </duration>
          requires notBool (Base in Addrs)
          [structural]
     syntax KItem ::= initCompoundLiteralHelper(K, SymBase)
     rule <k> initCompoundLiteralHelper(
                    initValue(X:CId, T:Type, Init:K),
                    Base:SymBase)
               => allocObject(Base, T)
               ~> addToEnv(X, Base)
               ~> giveType(X, T)
               ~> allowInit(Init)
               ~> sequencePoint
               ~> X
          ...</k>
          <compound-lit-map> M:Map => M[X <- Base] </compound-lit-map>
          <local-addresses>... .Set => SetItem(Base) </local-addresses>
          [structural]
     // This and the compound-lit-map is apparently needed to properly handle
     // gotos. An instance (i.e., syntactic occurance) of a compound literal
     // apparently must always refer to the same object, even if it is
     // encountered multiple times (e.g., when in the body of a loop).
     rule <k> initCompoundLiteral(initValue(X:CId, T:Type, Init:K))
               => addToEnv(X, Base)
               ~> giveType(X, T)
               ~> allowInit(Init)
               ~> sequencePoint
               ~> X
          ...</k>
          <local-addresses>... SetItem(Base) ...</local-addresses>
          <compound-lit-map>... X |-> Base:SymBase ...</compound-lit-map>
          [structural]

endmodule
