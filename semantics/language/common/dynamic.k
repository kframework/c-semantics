module C-DYNAMIC-SYNTAX
     syntax Type ::= t(Set, SimpleType) [klabel('t)]

     syntax Value ::= "skipval"

     syntax Agg ::= agg(List)

     syntax CValue ::= Bits | SymLoc | Float | Agg

     syntax TypedValue ::= tv(CValue, Type) 
          [klabel('tv), latex(renameTo \\ensuremath{{_}\\mathop{:}{_}})]

     syntax LValue ::= lv(SymLoc, Type) [klabel('lv)]
     syntax Value ::= lval(SymLoc, Type) [klabel('lval)]

     syntax Type ::= type(K) [function]
     syntax KItem ::= value(TypedValue) [function]

     syntax KItem ::= "discard"
     syntax Value ::= "emptyValue"
     
     syntax BaseValue ::= Float | Bits // Int is a subsort of Bits
     syntax C ::= BaseValue | Type | Value
     syntax Value ::= TypedValue
     syntax KResult ::= Value | Type

     syntax Status ::= "initializing" | "mainCalled" | "mainExited"

     syntax CabsLoc ::= "UnknownCabsLoc"

     // TODO(chathhorn): seems excessive to make this an CId. Also, it kinda
     // goes against our naming conventions.
     syntax CId ::= "file-scope"

     //  switchid, value (tv or 'Default)
     syntax CId ::= genLabel(Int, K) [klabel('genLabel)]
     syntax CId ::= funLabel(CId)
     syntax CId ::= case(Int)

     syntax KItem ::= "pushBlock"
     syntax KItem ::= "popBlock"

     syntax Statement ::= "loopMarked"
     syntax KItem ::= "popLoop"

     //  nesting-depth, currentBlock, decl
     syntax KItem ::= frozenDeclaration(Int, Int, K)
     //  nesting-depth, block history, continuation, loop stack, decl stack
     syntax KItem ::= gotoObject(Int, List, K, List, List)
          [latex(\terminal{gotoObj}\!({#1},{#2},{#3},{#4},{#5}\!))]


     syntax KItem ::= loadObj(K)
     syntax KItem ::= unwrapObj(Bag) [function]

endmodule

module C-DYNAMIC
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports COMPAT-SYNTAX

     rule value(tv(V:CValue, _)) => V

     rule type(tv(_, T:Type)) => T
     rule type(T:Type) => T
     rule type(lv(_, T:Type)) => T
     rule type(lval(_, T:Type)) => T

     rule CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc 
          [structural, anywhere]

     rule ExpressionLoc(K:K, _) => K
          [structural, anywhere]

     rule <k> CodeLoc(K:K, L:CabsLoc) => K ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
          [structural]

     rule _:KResult ~> discard => .
          [structural]

     rule discard => .
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
     rule Pragma(_:K) => .
          [structural]
          
     rule AttributeWrapper(K:K, _) => K [structural, anywhere]
     
     rule Identifier("___missing_field_name") => #NoName [structural, anywhere]

     rule NothingExpression => emptyValue

     rule unwrapObj(<generatedTop>... 
               <global> G:Bag </global> 
          ...</generatedTop>) 
          => bag2K(<global> G </global>)

     rule unwrapObj(.Bag) => bag2K(.Bag)

     rule <k> loadObj(bag2K(<global> G </global>)) => .K ...</k>
          <global> (_ => G) </global>
          when (isEmptyBag(G) =/=K true)
          [structural]

     rule loadObj(bag2K(.Bag)) => .K
          [structural]

     rule N:Int => tv(N, cfg:largestUnsigned)
          [structural] // for internal computations
     
     rule N:CSize => tv(N, cfg:largestUnsigned)
          [structural] // for internal computations
     
endmodule
