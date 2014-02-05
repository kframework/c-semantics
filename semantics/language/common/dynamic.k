module C-DYNAMIC-SYNTAX
     syntax Type ::= t(Set, SimpleType) [klabel('t)]

     syntax Value ::= "skipval"

     syntax Agg ::= agg(List)
     syntax CValue ::= Bits | Ptr | Float | Agg
     syntax TypedValue ::= tv(CValue, Type) 
          [klabel('tv), latex(renameTo \\ensuremath{{_}\\mathop{:}{_}})]

     syntax LValue ::= lv(SymLoc, Type) [klabel('lv)]
     syntax Value ::= lval(SymLoc, Type) [klabel('lval)]

     syntax Type ::= type(K) [function]
     syntax K ::= value(TypedValue) [function]

     syntax K ::= "discard"
     syntax Value ::= "emptyValue"
     
     syntax Int ::= "NullPointerConstant" [function]

     syntax BaseValue ::= Float | Bits // Int is a subsort of Bits
     syntax C ::= BaseValue | Type | Value
     syntax Value ::= TypedValue
     syntax KResult ::= Value | Type

     syntax Status ::= "initializing" | "mainCalled" | "mainExited"

     syntax CabsLoc ::= "UnknownCabsLoc"

     // TODO(chathhorn): seems excessive to make this an Id. Also, it kinda
     // goes against our naming conventions.
     syntax Id ::= "file-scope"

     //  switchid, value (tv or 'Default)
     syntax K ::= genLabel(Int, K) [klabel('genLabel)]

     syntax K ::= "pushBlock"
     syntax K ::= "popBlock"

     syntax Statement ::= "loopMarked"
     syntax K ::= "popLoop"

     //  nestingDepth, currentBlock, decl
     syntax K ::= frozenDeclaration(Int, Int, K)
     //  nestingDepth, block history, continuation, loop stack, decl stack
     syntax K ::= gotoObject(Int, List, K, List, List)
          [latex(\terminal{gotoObj}\!({#1},{#2},{#3},{#4},{#5}\!))]


     syntax K ::= loadObj(Bag)
     syntax Bag ::= unwrapObj(Bag) [function]

endmodule

module C-DYNAMIC
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
     imports COMPAT-SYNTAX

     rule value(tv(V:CValue, _)) => V

     rule type(tv(_, T:Type)) => T
     rule type(T:Type) => T
     rule type(lv(_, T:Type)) => T
     rule type(lval(_, T:Type)) => T

     rule NullPointerConstant => 0

     rule [unknown-loc]: 
          CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc 
          [structural, anywhere]

     rule [expression-loc]: ExpressionLoc(K:K, _) => K
          [structural, anywhere]

     rule [CodeLoc-k]:
          <k> CodeLoc(K:K, L:CabsLoc) => K ...</k>
          <currentProgramLoc> _ => L </currentProgramLoc>
          [structural]

     rule [discard]:
          _:KResult ~> discard => .
          [structural]

     rule [discard]:
          discard => .
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.10.6}{1}}}{
     A preprocessing directive of the form
     \cdisplay{# pragma pp-tokensoptnew-line}
     \broken{where the preprocessing token \cinline{STDC} does not immediately
     follow pragma in the directive (prior to any macro replacement)} causes the
     implementation to behave in an implementation-defined manner. The behavior
     might cause translation to fail or cause the translator or the resulting
     program to behave in a non-conforming manner. Any such pragma that is not
     recognized by the implementation is ignored.
     }*/
     rule [Pragma]: Pragma(_:K) => .
          [structural]
          
     rule AttributeWrapper(K:K, _) => K [structural, anywhere]
     
     rule Identifier("___missing_field_name") => #NoName [structural, anywhere]

     rule NothingExpression => emptyValue

     rule unwrapObj(<generatedTop>... 
               <global> G:Bag </global> 
          ...</generatedTop>) 
          => (<global> G </global>)

     rule unwrapObj(.Bag) => .Bag

     rule <k> loadObj(<global> G:Bag </global>) => .K ...</k>
          <global> (_:Bag => G) </global>
          when G =/=Bag .Bag
          [structural]

     rule loadObj(.Bag) => .K
          [structural]

endmodule
