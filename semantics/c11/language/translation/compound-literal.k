module C-COMPOUND-LITERAL
     imports C-CONFIGURATION
     imports LIST
     imports STRING
     imports C-ABSTRACT-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

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
     rule CompoundLiteral(N:Int, T:Type, K:K, Init:K)
          => #CompoundLiteral(compoundLiteral(N), DeclType(T, K), Init)

     syntax KItem ::= #CompoundLiteral(CId, K, K) [strict(2)]
     // TODO(chathhorn): rather ugly, done this way to avoid clashes with the
     // initializer cells when a compound literal appears in an initializer.
     rule <k> (.K => elaborateInit(declare(typedDeclaration(addStorage(Static(), T), X), Init)))
               ~> #CompoundLiteral(X:CId, T:Type, Init:K)
          ...</k>
          <curr-scope> fileScope </curr-scope>
          <env> Env:Map </env>
          requires notBool (X in_keys(Env))
     rule <k> (.K => elaborateInit(declare(typedDeclaration(T, X), Init)))
               ~> #CompoundLiteral(X:CId, T:Type, Init:K)
          ...</k>
          <curr-scope> Sc::Scope </curr-scope>
          <env> Env:Map </env>
          requires notBool (X in_keys(Env))
               andBool Sc =/=K fileScope
     rule <k> (elaborateDone(K:K) => .K) ~> #CompoundLiteral(_, _, _) ...</k>
          <elab>... .K => K </elab>
     rule <k> #CompoundLiteral(X:CId, _, _) => X ...</k>
          <env>... X |-> _ ...</env>

     /*@ \fromStandard{\source[n1570]{\para{6.4.5}{6}}}{For character string
     literals, the array elements have type \cinline{char}, and are initialized
     with the individual bytes of the multibyte character sequence. \ldots

     For wide string literals prefixed by the letter \cinline{L}, the array
     elements have type \cinline{wchar_t} and are initialized with the sequence
     of wide characters corresponding to the multibyte character sequence\ldots

     }*/

     rule <k> (.K => allocString(obj(0, 1, string(S)), S))
               ~> StringLiteral(S:String)
          ...</k>
          <mem> Mem:Map </mem>
          requires notBool (obj(0, 1, string(S)) in_keys(Mem))
     rule <k> StringLiteral(S:String)
               => lv(lnew(obj(0, 1, string(S))),
                    type(arrayType(type(char), lengthString(S) +Int 1)))
          ...</k>
          <mem>... obj(0, 1, string(S)) |-> _ ...</mem>

     rule WStringLiteral(list(S:List)) => wstringLiteral(S, byteAlignofType(type(cfg:wcharut)))

     syntax KItem ::= wstringLiteral(List, Int)
     // TODO(chathhorn): possibly do string allocation lazily, although we'd
     // want to make sure all allocations got triggered statically.
     rule <k> (.K => allocWString(obj(0, byteAlignofType(type(cfg:wcharut)), wstring(S)), S))
               ~> wstringLiteral(S:List, _)
          ...</k>
          <mem> Mem:Map </mem>
          requires notBool (obj(0, byteAlignofType(type(cfg:wcharut)), wstring(S)) in_keys(Mem))
     rule <k> wstringLiteral(S:List, Align:Int)
               => lv(lnew(obj(0, Align, wstring(S))),
                    type(arrayType(type(cfg:wcharut), size(S) +Int 1)))
          ...</k>
          <mem>... obj(0, Align, wstring(S)) |-> _ ...</mem>

endmodule
