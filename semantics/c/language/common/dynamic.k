// information used by execution and translation configuration and therefore
// included in all C and C++ modules
module C-DYNAMIC-SORTS
     imports COMMON-SORTS
     syntax LHold
     syntax RHold
     syntax NCLHold
     syntax RValue
     syntax LValue
     syntax Nclv
     syntax Hold
     syntax Scope
     syntax TrapLValue
     syntax Agg
     syntax Typed ::= LValue | RValue | Hold | Nclv | TrapLValue
endmodule

module C-REVAL-SYNTAX
     imports BASIC-K
     syntax KItem ::= reval(K)
endmodule

module C-DYNAMIC-SYNTAX
     imports BASIC-K
     imports FLOAT-SYNTAX
     imports INT-SYNTAX 
     imports K-REFLECTION
     imports LIST
     imports BITS-SORTS
     imports C-DYNAMIC-SORTS
     imports C-REVAL-SYNTAX
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS

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

     syntax Nclv ::= nclv(SymLoc, Type)
     syntax TrapLValue ::= trap(UType) [klabel(trap1)]
     syntax LValue ::= Nclv | LHold | NCLHold | TrapLValue
     syntax KResult ::= RValue | Type | UType | DType | Nclv | TrapLValue

     syntax BlockScope ::= blockScope(CId, Int)
     syntax PrototypeScope ::= "prototypeScope"
     syntax Scope ::= PrototypeScope | BlockScope

     //  switchid, caseid, value (tv or 'Default)
     syntax CId ::= caseLabel(Int, K)
     syntax CId ::= "funLabel"

     syntax CId ::= nativeFunction(Int)

     syntax KItem ::= pushBlock(Int) [klabel(pushBlock_C-DYNAMIC-SYNTAX)]
     syntax KItem ::= "popBlock"

     syntax Statement ::= "loopMarked"
     syntax KItem ::= "popLoop"

     //  nesting-depth, currentBlock, decl
     syntax KItem ::= frozenDeclaration(Int, K)
     //  block history, continuation, loop stack, decl stack
     syntax GotoObject ::= gotoObject(List, K, List, List)
          [latex(\terminal{gotoObj}\!({#1},{#2},{#3},{#4},{#5}\!))]

     syntax KItem ::= "comma"
     // these are semantic

     syntax KResult ::= initValue(CId, Type, K)
     syntax NoInit
     syntax KResult ::= NoInit

     syntax CompoundLiteralId ::= compoundLiteral(Int)
     syntax CId ::= CompoundLiteralId

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
     rule toHeatList(ListItem(K:KItem) L:List) => hItem(K) hs:: toHeatList(L)

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

     // Initializers.
     syntax InitLValue ::= LValue
                         | InitLValue "[[" Int "]]" [strict(1)]
                         | InitLValue ".init" CId [strict(1)]

     syntax EncodableValue ::= Opaque
     syntax Opaque ::= opaque(K, UType)
     syntax KItem ::= fromOpaque(CValue) [function]

endmodule

module C-DYNAMIC
     imports C-DYNAMIC-SYNTAX
     imports BOOL
     imports K-EQUAL
     imports C-CHECK-USE-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule isKResult(.HeatList) => true
     rule isKResult(S1::HeatItem hs:: S2::HeatList) => isKResult(S1) andBool isKResult(S2)

     context toRVal(HOLE:KItem => reval(HOLE)) [result(RValue)]

     rule stripHold(te(K:K, _)) => K
     rule stripHold(le(K:K, _)) => K
     rule stripHold(ncle(K:K, _)) => K
     rule stripHold(tv(_, _) #as V::RValue) => checkUse(V)
     rule stripHold(nclv(Loc::SymLoc, T::Type)) => lv(Loc, T)
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

     rule isNoInit(NoInit()) => true
     rule isNoInit(initValue(_, _, .K)) => true
     rule isNoInit(_) => false [owise]

     // don't fill holes beneath a compound assignment or postOp because that might capture stuff we don't want.
     rule fillRHoles(V:RValue, RHOLE) => V
     rule fillRHoles(V:RValue, Lbl:KLabel(L:K, R:K))
          => Lbl(fillRHoles(V, L), fillRHoles(V, R))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssign`) andBool #klabel(Lbl) =/=K #klabel(`postOp`)
     rule fillRHoles(_, K:K) => K [owise]

     rule fillLHoles(LV:K, LHOLE) => LV
     rule fillLHoles(LV:K, Lbl:KLabel(L:K, R:K))
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

     rule fromOpaque(opaque(V:K, _)) => V
     rule fromOpaque(_) => .K [owise]

endmodule
