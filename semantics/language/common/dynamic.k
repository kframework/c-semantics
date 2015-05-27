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
     syntax CompoundExpression ::= compoundExp(K)

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
     syntax KItem ::= enterBlock(BlockTag)
     syntax KItem ::= exitBlock(BlockTag)

     syntax Statement ::= "loopMarked"
     syntax KItem ::= "popLoop"

     //  nesting-depth, currentBlock, decl
     syntax KItem ::= frozenDeclaration(Int, Int, K)
     //  nesting-depth, block history, continuation, loop stack, decl stack
     syntax KItem ::= gotoObject(Int, List, K, List, List)
          [latex(\terminal{gotoObj}\!({#1},{#2},{#3},{#4},{#5}\!))]

     syntax KItem ::= loadObj(Bag)
     syntax Bag ::= unwrapObj(Bag) [function]

     syntax KItem ::= "comma"

     // these are semantic
     syntax KItem ::= reval(K)

     // Function id, param ids, prototype, body.
     syntax RValue ::= functionObject(CId, List, Type, K)

     syntax KResult ::= initValue(CId, Type, K)
     syntax KItem ::= allowInit(K)
     syntax NoInit
     syntax KResult ::= NoInit

     syntax BlockTag ::= Int | CId | "global"
                          // TODO(chathhorn): for restrict added via automatic
                          // casts -- not sure how to handle.
                          | "none"

     syntax CId ::= compoundLiteral(Int)
     syntax KItem ::= initCompoundLiteral(K) [strict]

     syntax KItem ::= typedef(CId, Type)
     syntax KItem ::= declareInternalVariable(CId, K, K) [strict(2,3)]

     //TODO(liyili2): might not need this list in the future.
     syntax HeatItem ::= hItem(K)
     context hItem(HOLE => reval(HOLE)) [ndheat, result(RValue)]
     syntax HeatList ::= List{HeatItem,"hs::"} [strict]
     syntax KItem ::= hlist(HeatList) [strict]
     syntax HeatList ::= toHeatList(List) [function]
     syntax List ::= hListToList(HeatList) [function]

     syntax HeatResult ::= hrItem(K)
     syntax HeatItem ::= HeatResult
     syntax KResult ::= HeatResult

     rule hItem(V:KResult) => hrItem(V)

     rule toHeatList(.List) => .HeatList
     rule toHeatList(ListItem(K:K) L:List) => hItem(K) hs:: toHeatList(L)

     rule hListToList(.HeatList) => .List
     rule hListToList(hrItem(K:K) hs:: HL:HeatList) => ListItem(K) hListToList(HL)

     syntax KItem ::= "LHOLE" | "RHOLE"
     syntax KItem ::= postOp(K, K) [strict(1)]
     syntax KItem ::= compoundAssign(K, K) [strict(1)]
     syntax KItem ::= fillLHoles(K, K) [function]
     syntax KItem ::= fillRHoles(RValue, K) [function]
endmodule

module C-DYNAMIC
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

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
     rule type(voidVal) => t(.Set, void)
     rule type(lv(_, T:Type)) => T
     rule type(nclv(_, T:Type)) => T
     rule type(te(_, T:Type)) => T
     rule type(le(_, T:Type)) => T
     rule type(ncle(_, T:Type)) => T

     rule _:KResult ~> discard => .K
          [structural]

     rule discard => .K
          [structural]

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

     rule isNoInit(NoInit) => true
     rule isNoInit(initValue(_, _, .K)) => true
     rule isNoInit(_) => false [owise]

     rule fillRHoles(V:RValue, RHOLE) => V
     rule fillRHoles(V:RValue, Lbl:KLabel(L:K,, R:K))
          => Lbl(fillRHoles(V, L),, fillRHoles(V, R))
     rule fillRHoles(_, K:K) => K [owise]

     rule fillLHoles(LV:KResult, LHOLE) => LV
     rule fillLHoles(LV:KResult, Lbl:KLabel(L:K,, R:K))
          => Lbl(fillLHoles(LV, L),, fillLHoles(LV, R))
     rule fillLHoles(_, K:K) => K [owise]
endmodule
