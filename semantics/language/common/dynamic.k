module C-DYNAMIC-SYNTAX
     imports INT-SYNTAX
     imports BASIC-K
     imports LIST
     imports FLOAT-SYNTAX
     imports STRING-SYNTAX
     imports SET

     syntax SimpleType // defined in C-TYPING-SYNTAX
     syntax Bits ::= Int // defined in C-BITS-SYNTAX
     syntax SymLoc // defined in C-SYMLOC-SYNTAX

     syntax Type ::= t(Set, SimpleType)

     syntax Agg ::= agg(List)

     syntax LValue ::= lv(SymLoc, Type)

     // These hold typed frozen computations -- one each for lvalues, rvalues,
     // and non-converted lvalues.
     syntax LHold ::= le(K, Type)
     syntax RHold ::= te(K, Type)
     syntax NCLHold ::= ncle(K, Type)
     syntax CompoundExpression ::= compoundExp(K)
     syntax Hold ::= LHold | RHold | NCLHold | CompoundExpression

     syntax KItem ::= stripHold(K) [function]

     syntax RValue ::= "voidVal"
     syntax RValue ::= "emptyValue"
     syntax RValue ::= tv(CValue, Type)
          [latex(renameTo \\ensuremath{{_}\\mathop{:}{_}})]

     syntax KItem ::= toRVal(K)

     syntax Typed ::= LValue | RValue | Hold | Type
     syntax Type ::= type(K) [function]
     syntax Valued ::= LValue | RValue | Hold
     syntax KItem ::= value(K) [function]

     syntax KItem ::= "discard"

     syntax NumValue ::= Float | Bits // Int is a subsort of Bits
     syntax CValue ::= NumValue | SymLoc | Agg
     syntax C ::= NumValue | Type | RValue

     syntax KResult ::= RValue | Type | nclv(SymLoc, Type) | trap(Type)

     syntax Status ::= "initializing" | "mainCalled" | "mainExited"

     syntax CabsLoc ::= "UnknownCabsLoc"

     syntax FileScope ::= "fileScope"
     syntax BlockScope ::= blockScope(CId, Int)
     syntax PrototypeScope ::= "prototypeScope"
     syntax Scope ::= FileScope | PrototypeScope | BlockScope | "none"

     //  switchid, caseid, value (tv or 'Default)
     syntax CId ::= caseLabel(Int, K)
     syntax CId ::= funLabel(CId)

     syntax KItem ::= pushBlock(Int)
     syntax KItem ::= "popBlock"

     syntax Statement ::= "loopMarked"
     syntax KItem ::= "popLoop"

     //  nesting-depth, currentBlock, decl
     syntax KItem ::= frozenDeclaration(Int, Int, K)
     //  nesting-depth, block history, continuation, loop stack, decl stack
     syntax KItem ::= gotoObject(Int, List, K, List, List)
          [latex(\terminal{gotoObj}\!({#1},{#2},{#3},{#4},{#5}\!))]

     syntax KItem ::= loadObj(K)
     syntax K ::= unwrapObj(K) [function]

     syntax KItem ::= "comma"

     // these are semantic
     syntax KItem ::= reval(K)

     // Function id, param ids, prototype, body.
     syntax RValue ::= functionObject(CId, List, Type, K)

     syntax KResult ::= initValue(CId, Type, K)
     syntax KItem ::= allowInit(K)
     syntax NoInit
     syntax KResult ::= NoInit

     syntax CId ::= compoundLiteral(Int)
     syntax KItem ::= initCompoundLiteral(K) [strict]

     syntax KItem ::= typedef(CId, Type)
     syntax KItem ::= declareInternalVariable(CId, K, K) [strict(2,3)]

     //TODO(liyili2): might not need this list in the future.
     syntax HeatItem ::= hItem(K)
     context hItem(HOLE:KItem => reval(HOLE)) [ndheat, result(RValue)]
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

     syntax Opts ::= CSV(String)
endmodule

module C-DYNAMIC
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     rule isKResult(.HeatList) => true
     rule isKResult(S1::HeatItem hs:: S2::HeatList) => isKResult(S1) andBool isKResult(S2)

     context toRVal(HOLE:KItem => reval(HOLE)) [result(RValue)]

     rule stripHold(te(K:K, _)) => K
     rule stripHold(le(K:K, _)) => K
     rule stripHold(ncle(K:K, _)) => K
     rule stripHold(K:K) => K [owise]

     rule value(tv(V:CValue, _)) => V
     rule value(nclv(Loc:SymLoc, _)) => Loc
     rule value(te(K:K, _)) => K
     rule value(le(K:K, _)) => K
     rule value(ncle(K:K, _)) => K
     rule value(compoundExp(K:K)) => K

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

     rule unwrapObj(.K) => .K

     rule <k> loadObj(G:GlobalCell) => .K ...</k>
          (<global> _ </global> => G)
          requires (G =/=K .K)
          [structural]

     rule loadObj(.K) => .K
          [structural]

     rule N:Int => tv(N, t(.Set, cfg:largestUnsigned))
          [structural] // for internal computations

     rule <k> allowInit(K:K) => K ~> initDone(I) ...</k>
          <initializing> I:Bool => true </initializing>
          [structural]

     syntax KItem ::= initDone(Bool)
     rule <k> R:KResult ~> initDone(I:Bool) => R ...</k>
          <initializing> _ => I </initializing>
          [structural]
     rule <k> initDone(I:Bool) => .K ...</k>
          <initializing> _ => I </initializing>
          [structural]

     rule isNoInit(NoInit) => true
     rule isNoInit(initValue(_, _, .K)) => true
     rule isNoInit(_) => false [owise]

     rule fillRHoles(V:RValue, RHOLE) => V
     rule fillRHoles(V:RValue, Lbl:KLabel(L:K, R:K))
          => Lbl(fillRHoles(V, L), fillRHoles(V, R))
     rule fillRHoles(_, K:K) => K [owise]

     rule fillLHoles(LV:KResult, LHOLE) => LV
     rule fillLHoles(LV:KResult, Lbl:KLabel(L:K, R:K))
          => Lbl(fillLHoles(LV, L), fillLHoles(LV, R))
     rule fillLHoles(_, K:K) => K [owise]

endmodule
