module C-DYNAMIC-SYNTAX
     imports INT-SYNTAX
     imports BASIC-K
     imports LIST
     imports FLOAT-SYNTAX
     imports SET

     syntax SimpleType // defined in C-TYPING-SYNTAX
     syntax Bits // defined in C-BITS-SYNTAX
     syntax SymLoc // defined in C-SYMLOC-SYNTAX

     syntax Type ::= t(Set, SimpleType)

     syntax Agg ::= agg(List)

     syntax LValue ::= lv(SymLoc, Type)

     syntax KItem ::= le(K, Type)
     syntax Hold ::= te(K, Type)
     syntax LHold ::= ncle(K, Type)

     syntax KItem ::= stripHold(K) [function]

     syntax RValue ::= "voidVal"
     syntax RValue ::= "emptyValue"
     syntax RValue ::= tv(CValue, Type)
          [latex(renameTo \\ensuremath{{_}\\mathop{:}{_}})]

     syntax KItem ::= toRVal(K)

     syntax Type ::= type(K) [function]
     syntax KItem ::= value(K) [function]

     syntax KItem ::= "discard"

     syntax NumValue ::= Float | Bits // Int is a subsort of Bits
     syntax CValue ::= NumValue | SymLoc | Agg
     syntax C ::= NumValue | Type | RValue

     syntax KResult ::= RValue | Type | nclv(SymLoc, Type) | trap(Type)

     syntax Status ::= "initializing" | "mainCalled" | "mainExited"

     syntax CabsLoc ::= "UnknownCabsLoc"

     // TODO(chathhorn): seems excessive to make this an CId. Also, it kinda
     // goes against our naming conventions.
     syntax CId ::= "file-scope"

     //  switchid, caseid, value (tv or 'Default)
     syntax CId ::= caseLabel(Int, K)
     syntax CId ::= funLabel(CId)

     syntax KItem ::= "pushBlock"
     syntax KItem ::= "popBlock"
     syntax KItem ::= enterBlock(Int)
     syntax KItem ::= exitBlock(Int)

     syntax Statement ::= "loopMarked"
     syntax KItem ::= "popLoop"

     //  nesting-depth, currentBlock, decl
     syntax KItem ::= frozenDeclaration(Int, Int, K)
     //  nesting-depth, block history, continuation, loop stack, decl stack
     syntax KItem ::= gotoObject(Int, List, K, List, List)
          [latex(\terminal{gotoObj}\!({#1},{#2},{#3},{#4},{#5}\!))]

     syntax KItem ::= loadObj(Bag)
     syntax Bag ::= unwrapObj(Bag) [function]

     syntax KItem ::= "sequencePoint"

     syntax KItem ::= "comma"

     // Function id, param ids, prototype, body.
     syntax RValue ::= functionObject(CId, List, Type, K)

     syntax KResult ::= initValue(CId, Type, K)
     syntax KItem ::= allowInit(K)

endmodule

module C-DYNAMIC
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports COMPAT-SYNTAX

     context toRVal(HOLE => reval(HOLE)) [result(RValue)]
     rule toRVal(V:RValue) => V
          [structural]

     rule stripHold(te(K:K, _)) => K
     rule stripHold(le(K:K, _)) => K
     rule stripHold(ncle(K:K, _)) => K
     rule stripHold(K:K) => K [owise]

     rule value(tv(V:CValue, _)) => V
     rule value(nclv(Loc:SymLoc, _)) => Loc
     rule value(te(K:K, _)) => K
     rule value(le(K:K, _)) => K
     rule value(ncle(K:K, _)) => K

     rule type(tv(_, T:Type)) => T
     rule type(T:Type) => T
     rule type(lv(_, T:Type)) => T
     rule type(nclv(_, T:Type)) => T
     rule type(te(_, T:Type)) => T
     rule type(le(_, T:Type)) => T
     rule type(ncle(_, T:Type)) => T

     rule ExpressionLoc(K:K, _) => K

     rule _:KResult ~> discard => .K
          [structural]

     rule discard => .K
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
     rule Pragma(_) => .K
          [structural]
     rule PragmaKccInv(_) => .K
          [structural]

     rule AttributeWrapper(K:K, _) => K

     rule ToIdentifier("___missing_field_name") => #NoName
     rule ToIdentifier(S:String) => Identifier(S)
          requires S =/=String "___missing_field_name"

     rule NothingExpression => emptyValue:>Expression

     rule unwrapObj(<generatedTop>...
               <global> G:Bag </global>
          ...</generatedTop>)
          => <global> G </global>

     rule unwrapObj(.Bag) => .Bag

     rule <k> loadObj(<global> G:Bag </global>) => .K ...</k>
          <global> (_:Bag => G) </global>
          requires (G =/=Bag .Bag)
          [structural]

     rule loadObj(.Bag) => .K
          [structural]

     rule N:Int => tv(N, t(.Set, cfg:largestUnsigned))
          [structural] // for internal computations

     rule N:CSize => tv(N, t(.Set, cfg:largestUnsigned))
          [structural] // for internal computations

     rule <k> allowInit(K:K) => K ~> initDone ...</k>
          <initializing> I:Int => I +Int 1 </initializing>
          [structural]

     syntax KItem ::= "initDone"
     rule <k> R:KResult ~> initDone => R ...</k>
          <initializing> I:Int => I -Int 1 </initializing>
          [structural]
     rule <k> initDone => .K ...</k>
          <initializing> I:Int => I -Int 1 </initializing>
          [structural]

endmodule
