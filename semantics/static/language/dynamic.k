require "process-label.k"
require "static.k"
require "io-direct.k"

module C-DYNAMIC-SYNTAX
     syntax K ::= "sequencePoint"
     syntax Type ::= t(Set, SimpleType) [klabel('t)]

     syntax Value ::= "skipval"
     syntax TypedValue ::= tv(KList, Type) 
          [klabel('tv), latex(renameTo \\ensuremath{{_}\\mathop{:}{_}})]
     syntax LValue ::= "lv" "(" SymLoc "," Type ")" [klabel('lv)]
     syntax Value ::= "lval" "(" SymLoc "," Type ")" [klabel('lval)]

     syntax Type ::= type(K) [function]
     syntax K ::= value(TypedValue) [function]

     syntax K ::= "discard"
     syntax Value ::= "emptyValue"
     
     syntax Int ::= "NullPointerConstant" [function]

     syntax K ::= "resolveReferences"
     syntax K ::= "pgmArgs" "(" KList ")" [function]
     syntax K ::= "incomingArguments" "(" KList ")" [klabel('incomingArguments)]
     syntax K ::= "callMain" "(" Int "," K ")" [klabel('callMain)]
     syntax K ::= "callMain-aux" "(" K "," Int "," Id "," K ")" [strict(1)]

     syntax Status ::= "initializing" | "mainCalled" | "mainExited"

     syntax BaseValue ::= Float | Bits // Int is a subsort of Bits
     syntax C ::= BaseValue | Type | Value
     syntax Value ::= TypedValue
     syntax KResult ::= Value | Type
endmodule

module C-DYNAMIC
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DECLARATION-SYNTAX

     imports COMPAT-SYNTAX

     rule value(tv(V:KList, _)) => V

     rule type(tv(_, T:Type)) => T
     rule type(T:Type) => T
     rule type(lv(_, T:Type)) => T
     rule type(lval(_, T:Type)) => T

     rule NullPointerConstant => 0

     syntax CabsLoc ::= "UnknownCabsLoc"
     rule [unknown-loc]: 
          CabsLoc("cabs loc unknown", -10, -10, 0) => UnknownCabsLoc 
          [structural, anywhere]

     rule [expression-loc]: ExpressionLoc(K:K, _) => K
          [structural, anywhere]

     rule [CodeLoc-k]:
          <k> CodeLoc(K:K, L:CabsLoc) => K ...</k>
          <currentProgramLoc> _ => L </currentProgramLoc>
          [structural]
          
     rule [sequencePoint]:
          sequencePoint => .
          [structural]

     rule [discard]:
          _:KResult ~> discard => .
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
     
     rule <k> Program(klist(P:KList)) => klistToK(P) ...</k>
          <nextLoc> _ => firstLoc(1) </nextLoc>
          <threadLocal>...
               <control>...
                    <currentFunction> 
                         _ => file-scope
                    </currentFunction>
                    <currentProgramLoc>
                         _ => UnknownCabsLoc
                    </currentProgramLoc>
               ...</control>
          ...</threadLocal>
          <nextSharedLoc> _ => firstLoc(0) </nextSharedLoc>
          [structural, large]

endmodule

module C
     imports C-SYNTAX

     imports C-COMMON

     imports C-DYNAMIC
     imports C-STATIC
     imports C-PROCESS-LABEL
     imports C-IO-DIRECT
endmodule
