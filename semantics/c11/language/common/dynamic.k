// information used by execution and translation configuration and therefore
// included in all C and C++ modules
module C-DYNAMIC-SORTS
     syntax LHold
     syntax RHold
     syntax NCLHold
     syntax RValue
     syntax LValue
     syntax Nclv
     syntax Hold
     syntax Scope
     syntax NumValue
     syntax CValue
     syntax TrapLValue
     syntax Typed ::= LValue | RValue | Hold | Nclv | TrapLValue
endmodule

module C-REVAL-SYNTAX
     imports BASIC-K
     syntax KItem ::= reval(K)
endmodule

module C-DYNAMIC-SYNTAX
     imports C-REVAL-SYNTAX
     imports C-DYNAMIC-SORTS
     imports BASIC-K
     imports FLOAT-SYNTAX
     imports INT-SYNTAX 
     imports LIST
     imports BITS-SORTS
     imports SYMLOC-SORTS
     imports C-TYPING-SORTS

     syntax Agg ::= agg(List)

     syntax LValue ::= lv(SymLoc, Type)

     // These hold typed frozen computations -- one each for lvalues, rvalues,
     // and non-converted lvalues.
     syntax LHold ::= le(K, Type)
     syntax RHold ::= te(K, UType)
     syntax NCLHold ::= ncle(K, Type)
     syntax CompoundExpression ::= compoundExp(K)
     syntax Hold ::= LHold | RHold | NCLHold | CompoundExpression

     syntax KItem ::= stripHold(K) [function]

     syntax RValue ::= "voidVal" [klabel(voidVal)]
     syntax RValue ::= "emptyValue"
     syntax RValue ::= tv(CValue, UType)
          [latex(renameTo \\ensuremath{{_}\\mathop{:}{_}})]

     syntax KItem ::= toRVal(K)

     syntax Typed ::= Type

     syntax Valued ::= LValue | RValue | Hold
     syntax KItem ::= value(K) [function]

     syntax KItem ::= "discard"

     syntax NumValue ::= Float | Bits // Int is a subsort of Bits
     syntax CValue ::= SymLoc | Agg
     syntax EffectiveValue ::= CValue
     syntax C ::= NumValue | Type | RValue

     syntax Nclv ::= nclv(SymLoc, Type)
     syntax TrapLValue ::= trap(UType) [klabel(trap1)]
     syntax KResult ::= RValue | Type | UType | DType | Nclv | TrapLValue

     syntax BlockScope ::= blockScope(CId, Int)
     syntax PrototypeScope ::= "prototypeScope"
     syntax Scope ::= PrototypeScope | BlockScope

     //  switchid, caseid, value (tv or 'Default)
     syntax CId ::= caseLabel(Int, K)
     syntax CId ::= funLabel(CId)

     syntax CId ::= nativeFunction(Int)

     syntax KItem ::= pushBlock(Int) [klabel(pushBlock_C-DYNAMIC-SYNTAX)]
     syntax KItem ::= "popBlock"

     syntax Statement ::= "loopMarked"
     syntax KItem ::= "popLoop"

     //  nesting-depth, currentBlock, decl
     syntax KItem ::= frozenDeclaration(Int, Int, K)
     //  nesting-depth, block history, continuation, loop stack, decl stack
     syntax KItem ::= gotoObject(Int, List, K, List, List)
          [latex(\terminal{gotoObj}\!({#1},{#2},{#3},{#4},{#5}\!))]

     syntax KItem ::= "comma"
     // these are semantic

     syntax KResult ::= initValue(CId, Type, K)
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

     syntax Bool ::= allRValueInHeatList(HeatList) [function]

     syntax HeatResult ::= hrItem(RValue)
     syntax HeatItem ::= HeatResult
     syntax KResult ::= HeatResult

     rule hItem(V:RValue) => hrItem(V)

     rule toHeatList(.List) => .HeatList
     rule toHeatList(ListItem(K:K) L:List) => hItem(K) hs:: toHeatList(L)

     rule hListToList(.HeatList) => .List
     rule hListToList(hrItem(V:RValue) hs:: HL:HeatList) => ListItem(V) hListToList(HL)

     syntax KItem ::= "LHOLE" | "RHOLE"
     syntax KItem ::= postOp(K, K) [strict(1)]
     syntax KItem ::= compoundAssign(K, K) [strict(1)]
     syntax KItem ::= fillLHoles(K, K) [function]
     syntax KItem ::= fillRHoles(RValue, K) [function]

     syntax KItem ::= "checkStackDepth"

     syntax Bool ::= isNCLKLabel(K) [function, klabelPredicate]
                   | isRKLabel(K) [function, klabelPredicate]
endmodule

module C-DYNAMIC
     imports C-DYNAMIC-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports K-EQUAL
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

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

     rule type(tv(_, T::UType)) => type(T)
     rule type(voidVal) => type(void)
     rule type(lv(_, T::Type)) => T
     rule type(nclv(_, T::Type)) => T
     rule type(te(_, T::UType)) => type(T)
     rule type(le(_, T::Type)) => T
     rule type(ncle(_, T::Type)) => T
     rule type(trap(T::UType)) => type(T)

     rule utype(tv(_, T::UType)) => T
     rule utype(voidVal) => utype(void)
     rule utype(lv(_, T::Type)) => utype(T)
     rule utype(nclv(_, T::Type)) => utype(T)
     rule utype(te(_, T:UType)) => T
     rule utype(le(_, T::Type)) => utype(T)
     rule utype(ncle(_, T::Type)) => utype(T)
     rule utype(trap(T::UType)) => T

     rule _:KResult ~> discard => .K
          [structural]

     rule discard => .K
          [structural]

     rule N:Int => tv(N, utype(cfg:largestUnsigned))
          [structural] // for internal computations

     rule <k> allowInit(K:K) => K ~> initDone(I) ...</k>
          <initializing> I:Bool => true </initializing>
          [structural]

     syntax KItem ::= initDone(Bool)
     rule <k> R:KResult ~> initDone(I::Bool) => R ...</k>
          <initializing> _ => I </initializing>
          [structural]
     rule <k> initDone(I::Bool) => .K ...</k>
          <initializing> _ => I </initializing>
          [structural]

     rule isNoInit(NoInit()) => true
     rule isNoInit(initValue(_, _, .K)) => true
     rule isNoInit(_) => false [owise]

     // don't fill holes beneath a compound assignment or postOp because that might capture stuff we don't want.
     rule fillRHoles(V:RValue, RHOLE) => V
     rule fillRHoles(V:RValue, Lbl:KLabel(L:K, R:K))
          => Lbl(fillRHoles(V, L), fillRHoles(V, R))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssign`) andBool #klabel(Lbl) =/=K #klabel(`postOp`)
     rule fillRHoles(_, K:K) => K [owise]

     rule fillLHoles(LV:KResult, LHOLE) => LV
     rule fillLHoles(LV:KResult, Lbl:KLabel(L:K, R:K))
          => Lbl(fillLHoles(LV, L), fillLHoles(LV, R))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssign`) andBool #klabel(Lbl) =/=K #klabel(`postOp`)
     rule fillLHoles(_, K:K) => K [owise]

     rule isNCLKLabel(#klabel(`nclv`)) => true
     rule isNCLKLabel(#klabel(`ncle`)) => true
     rule isNCLKLabel(_) => false [owise]

     rule isRKLabel(#klabel(`tv`)) => true
     rule isRKLabel(#klabel(`te`)) => true
     rule isRKLabel(_) => false [owise]

     rule allRValueInHeatList(.HeatList) => true
     rule allRValueInHeatList(hItem(_) hs:: _) => false
     rule allRValueInHeatList(hrItem(_) hs:: HL:HeatList)
          => allRValueInHeatList(HL)
endmodule
