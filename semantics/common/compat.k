module COMPAT-SORTS
     syntax StrictList
     syntax StrictListResult
     syntax Predicate
endmodule

module COMPAT-SYNTAX
     imports COMPAT-SORTS
     imports COMMON-SYNTAX
     imports LIST

     syntax String ::= firstChar(String) [function]
     syntax String ::= lastChar(String) [function]
     syntax String ::= nthChar(String, Int) [function]
     syntax String ::= butFirstChar(String) [function]

     syntax List ::= stringToList(String) [function]
     syntax String ::= listToString(List) [function]

     syntax String ::= showK(K) [function, hook(C_SEMANTICS.kToString)]
     syntax String ::= showCId(CId) [function]
     syntax String ::= showInt(Int) [function]
     syntax String ::= showFloat(Float) [function]

     syntax String ::= toUpperCase(String) [function]

     syntax Bool ::= all(List, Predicate) [function]
     syntax Bool ::= some(List, Predicate) [function]

     syntax List ::= removeListItem(List, K) [function]

     syntax StrictListResult ::= krlist(List)
     syntax StrictList ::= StrictListResult
     syntax KResult ::= StrictListResult

     syntax List ::= reverseList(List) [function]

     syntax StrictList ::= list(List) [symbol]
     syntax KItem ::= set(Set)

     syntax K ::= listToK(List) [function]
     syntax List ::= kSeqToList(K) [function, symbol]

     syntax KTuple ::= kpair(K, K)
                    | ktriple(K, K, K)

     syntax K ::= fst(KTuple) [function]
                | snd(KTuple) [function]

     syntax List ::= Int "to" Int [function]

     syntax List ::= times(Int, K) [function]

     syntax Set ::= filterSet(Set, Predicate) [function]
     syntax List ::= filterList(List, Predicate) [function]

     syntax Bool ::= Predicate "(" K ")" [function, avoid]

     syntax Set ::= listToSet(List) [function]

     syntax Bool ::= some(Set, Predicate) [function]
                   | some(Map, K) [function]

     syntax Int ::= ceilDiv(Int, Int) [function]
     syntax List ::= mapList(List, K) [function]
                   | flatMapList(List, K) [function]

     // Takes maps M1, M2 and returns a map M with x |-> M2[M1[x]] for all x in M1.
     syntax Map ::= composeMaps(Map, Map) [function]

     // Turns a (hopefully injective!) map with {k_1 |-> v_1, ..., k_n |-> v_n} into {v_1 |-> k_1, ..., v_n |-> k_n}.
     syntax Map ::= invertMap(Map) [function]

     syntax Map ::= Map "[" K "," K "<-" K "]" [function]
     syntax Map ::= Map "[" K "+=" K "]" [function]
     syntax Map ::= Map "[" K "<+" Map "]" [function]
     syntax Bool ::= K "," K "in_keys" "(" Map ")" [function]

     // implements List[Idx <- Val]
     syntax List ::= myListUpdate(List, Int, KItem) [function]


     // Range map. It is recommended to use .rangeMap and rangeMapAppendSorted
     // to construct it.
     syntax RangeMap
     // A range item contains all integers between start and end, including both
     // ends.
     syntax RangeMapItem ::= rangeMapItem(start:Int, end:Int)
     syntax MaybeRangeMapItem ::= RangeMapItem | "noRangeMapItem"

     syntax RangeMap ::= ".RangeMap"  [function]
     syntax RangeMap ::= rangeMapAppendSorted(RangeMap, RangeMapItem)  [function]
     // The elements in the two maps must be either identical, or disjoint.
     syntax RangeMap ::= mergeRangeMaps(RangeMap, RangeMap)  [function]

     syntax Bool ::= rangeMapContains(RangeMap, value:Int)  [function]
     syntax MaybeRangeMapItem ::= rangeMapFind(RangeMap, value:Int)

endmodule

module COMPAT-KAST [kast]
     imports COMPAT-SYNTAX
     imports MAP
     imports BOOL
     imports K-EQUAL

     rule some(.Map::Map, Lbl:K) => false
     rule some(K1:KItem |-> K2:KItem M::Map, #klabel(Lbl:KLabel)) => Lbl(K1, K2) orBool some(M, #klabel(Lbl)) [owise]

     rule mapList(ListItem(K:KItem) L:List, #klabel(Lbl:KLabel)) => ListItem(Lbl(K)) mapList(L, #klabel(Lbl))
     rule mapList(.List, _) => .List
     rule flatMapList(ListItem(K:KItem) L:List, #klabel(Lbl:KLabel)) => {Lbl(K)}:>List flatMapList(L, #klabel(Lbl))
     rule flatMapList(.List, _) => .List
endmodule

module COMPAT
     imports COMPAT-SYNTAX
     imports COMPAT-KAST
     imports C-TYPING-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports BOOL
     imports LIST
     imports MAP
     imports STRING

     rule all(ListItem(K:KItem) L:List, P:Predicate)
          => P(K) andBool all(L, P)
     rule all(.List, _) => true

     rule some(ListItem(K:KItem) L:List, P:Predicate)
          => P(K) orBool some(L, P)
     rule some(.List, _) => false

     rule filterSet(SetItem(K:KItem) S:Set, Pred:Predicate)
          => #filterSet(K, S, Pred)
     rule filterSet(.Set, _)
          => .Set

     syntax Set ::= #filterSet(K, Set, Predicate) [function]
     rule #filterSet(K:KItem, .Set, Pred:Predicate)
          => SetItem(K)
          requires Pred(K) ==K true
     rule #filterSet(K:K, .Set, Pred:Predicate)
          => .Set
          requires Pred(K) =/=K true
     rule #filterSet(K:KItem, SetItem(K':KItem) S:Set, Pred:Predicate)
          => SetItem(K) #filterSet(K', S, Pred)
          requires Pred(K) ==K true
     rule #filterSet(K:K, SetItem(K':KItem) S:Set, Pred:Predicate)
          => #filterSet(K', S, Pred)
          requires Pred(K) =/=K true

     rule filterList(ListItem(K:KItem) L:List, Pred:Predicate)
          => #filterList(K, L, Pred)
     rule filterList(.List, _)
          => .List

     syntax List ::= #filterList(K, List, Predicate) [function]
     rule #filterList(K:KItem, .List, Pred:Predicate)
          => ListItem(K)
          requires Pred(K) ==K true
     rule #filterList(K:K, .List, Pred:Predicate)
          => .List
          requires Pred(K) =/=K true
     rule #filterList(K:KItem, ListItem(K':KItem) L:List, Pred:Predicate)
          => ListItem(K) #filterList(K', L, Pred)
          requires Pred(K) ==K true
     rule #filterList(K:K, ListItem(K':KItem) L:List, Pred:Predicate)
          => #filterList(K', L, Pred)
          requires Pred(K) =/=K true

     rule some(S:Set, P:Predicate) => some'(.K, S, P)

     syntax Bool ::= "some'" "(" K "," Set "," Predicate ")" [function]
     rule some'(.K, SetItem(K:KItem) S:Set, P:Predicate) => some'(K, S, P)
     rule some'(K:K, _, P:Predicate) => true
          requires P(K) ==K true
     rule some'(K:K, S:Set, P:Predicate) => some'(.K, S, P)
          requires P(K) =/=K true
               andBool (K =/=K .K)
     rule some'(.K, .Set, _) => false

     rule stringToList("") => .List
     rule stringToList(S:String)
               => ListItem(firstChar(S:String))
                    stringToList(butFirstChar(S:String))
          requires S:String =/=String ""

     rule listToString(.List) => ""
     rule listToString((ListItem(S:String) L:List))
               => S:String +String listToString(L:List)

     rule showCId(Identifier(S:String)) => S
     rule showCId(#NoName) => "<anonymous>"
     rule showCId(#NoName(_)) => "<anonymous>"
     rule showCId(vararg(N::Int)) => "<vararg " +String showInt(N) +String ">"
     rule showCId(_::CId) => "<unknown>" [owise]

     rule [[ showCId(X::UnnamedCId) => "<anonymous at " +String File +String ":" +String showInt(Line) +String ">" ]]
          <unnamed-locs>... X |-> CabsLoc(File::String, _, Line::Int, _, _) ...</unnamed-locs>

     rule showInt(V::Int) => Int2String(V)

     rule showFloat(V::Float) => Float2String(V)

     rule firstChar(S::String) => substrString(S, 0, 1)
          requires lengthString(S) >=Int 1
     rule firstChar(_) => "" [owise]

     rule lastChar(S::String) => nthChar(S, lengthString(S) -Int 1)
          requires lengthString(S) >=Int 1
     rule lastChar(_) => "" [owise]

     rule nthChar(S::String, N::Int) => substrString(S, N, N +Int 1)
          requires N <Int lengthString(S)
               andBool N >=Int 0
     rule nthChar(_, _) => "" [owise]

     rule butFirstChar(S::String)
          => substrString(S, 1, lengthString(S:String))
          requires lengthString(S) >=Int 2
     rule butFirstChar(_) => "" [owise]

     rule toUpperCase("") => ""
     rule toUpperCase(C::String) => C
          requires (lengthString(C) ==Int 1)
               andBool (ordChar(C) <Int ordChar("a")
                    orBool ordChar(C) >Int ordChar("z"))
     rule toUpperCase(C::String)
          => chrChar(absInt(ordChar(C)
               -Int (ordChar("a") -Int ordChar("A"))))
          requires (lengthString(C) ==Int 1)
               andBool (ordChar(C) >=Int ordChar("a")
                    andBool ordChar(C) <=Int ordChar("z"))
     rule toUpperCase(S::String)
          => toUpperCase(firstChar(S:String))
               +String toUpperCase(butFirstChar(S:String))
          requires lengthString(S) >Int 1

     rule removeListItem(.List, _) => .List
     rule removeListItem(ListItem(A:KItem) M:List, A) => M
     rule removeListItem(ListItem(A:KItem) M:List, A':K)
          => ListItem(A) removeListItem(M, A')
          requires A =/=K A'

     syntax Bool ::= subset(KItem, Set, Set) [function]
     rule subset(K:KItem, S1:Set, S2:Set) => S1 <=Set (S2 -Set SetItem(K))
          requires K in S2
     rule subset(K:KItem, _, S2:Set) => false
          requires notBool (K in S2)

     syntax Map ::= removeBagItemFromMap(Map, K) [function]
     rule removeBagItemFromMap(K |-> 1 M::Map, K:KItem) => M
     rule removeBagItemFromMap(K |-> I::Int M::Map, K:KItem) => K |-> (I -Int 1) M

     syntax List ::= reverseAppendList(List, List) [function]
     rule reverseAppendList(.List, L::List) => L
     rule reverseAppendList(ListItem(K:KItem) L::List, L2::List)
          => reverseAppendList(L, ListItem(K) L2)

     rule reverseList(L::List) => reverseAppendList(L, .List)

     rule listToK(ListItem(K:KItem) L:List) => K ~> listToK(L)
     rule listToK(.List) => .K

     rule kSeqToList(K1:KItem ~> K:K) => ListItem(K1) kSeqToList(K)
     rule kSeqToList(.K) => .List

     rule N:Int to N => .List
     rule N:Int to N':Int => ListItem(N)  ((N +Int 1) to N')
          requires N <Int N'

     rule times(0, _) => .List
     rule times(N:Int, K:KItem) => ListItem(K) times(N -Int 1, K)
          requires N >Int 0

     rule listToSet(ListItem(K:KItem) Tail::List) => SetItem(K) listToSet(Tail)
     rule listToSet(.List) => .Set

     rule ceilDiv(X:Int, Y:Int) => (X +Int Y -Int 1) /Int Y

     rule ((A |-> S::Set) M::Map) [A:KItem += B:KItem] => (A |-> (S SetItem(B))) M
     rule M::Map [A:KItem += B:KItem] => M A |-> SetItem(B) [owise]

     rule ((A |-> M2::Map) M1::Map) [A:KItem <+ B::Map] => (A |-> (M2 B)) M1
     rule M::Map [A:KItem <+ B::Map] => M A |-> B [owise]

     rule fst(kpair(K:K, _)) => K
     rule snd(kpair(_, K:K)) => K

     rule composeMaps((X::KItem |-> Y::KItem) M1::Map, (Y::KItem |-> Z::KItem) M2::Map)
          => (X |-> Z) composeMaps(M1, M2)
     rule composeMaps(_, _) => .Map [owise]

     rule invertMap(K::KItem |-> V::KItem M::Map) => (V |-> K) invertMap(M)
     rule invertMap(.Map) => .Map


     syntax List ::= #myListUpdate(List, List, Int, KItem) [function]

     rule myListUpdate(L::List, Idx::Int, V::KItem)
          => #myListUpdate(.List, L, Idx, V)

     rule #myListUpdate(L1::List, ListItem(_) L2::List, 0, V::KItem)
          => L1 ListItem(V) L2

     rule #myListUpdate(
               _::List (.List => ListItem(V)),
               (ListItem(V::KItem) => .List) _,
               N::Int => N -Int 1,
               _
          )
          requires N >Int 0


     // The list must be sorted, must contain only RangeMapItem, and the ranges
     // must be disjoint.
     syntax RangeMap ::= rangeMap(List)

     syntax RangeMap ::= #mergeRangeMaps(first:RangeMap, second:RangeMap, merged:RangeMap)  [function]

     // (the address at 'start' is <= 'addr') or (start == 0)
     // (the address at 'end' is >= 'addr') or (end == last-element).
     // If only one of them is equal to 'addr', we change the other one.
     syntax MaybeRangeMapItem ::= #rangeMapFind(RangeMap, value:Int, start:Int, end:Int)  [function]
     syntax MaybeRangeMapItem ::= #rangeMapFindChoice(RangeMap, addr:Int, start:Int, middle:Int, middleItem:RangeMapItem, end:Int)  [function]

     syntax MaybeRangeMapItem ::= #checkInRangeMapItem(value:Int, RangeMapItem)  [function]
     syntax MaybeRangeMapItem ::= #firstRangeMapItem(MaybeRangeMapItem, MaybeRangeMapItem)  [function]

     syntax Bool ::= isInRangeMapItem(addr:Int, RangeMapItem) [function]
     syntax RangeMapItem ::= asRangeMapItem(KItem)  [function]

     rule rangeMapContains(M:RangeMap, Value:Int)
               => isRangeMapItem(rangeMapFind(M, Value))

     rule rangeMapFind(rangeMap(L:List) #as M:RangeMap, Value:Int)
          => #rangeMapFind(M, Value, 0, size(L) -Int 1)
          requires size(L) >Int 0
     rule rangeMapFind(rangeMap(L:List), _:Int) => noRangeMapItem
          requires size(L) ==Int 0

     rule #rangeMapFind(rangeMap(L:List), Value:Int, Start:Int, Start)
          => #checkInRangeMapItem(Value, asRangeMapItem(L[Start]))
     rule #rangeMapFind(rangeMap(L:List), Value:Int, Start:Int, End:Int)
          => #firstRangeMapItem(
               #checkInRangeMapItem(Value, asRangeMapItem(L[Start])),
               #checkInRangeMapItem(Value, asRangeMapItem(L[End]))
          )
          requires Start ==Int End -Int 1
     rule #rangeMapFind(rangeMap(L:List) #as M:RangeMap, Value:Int, Start:Int, End:Int)
          => #rangeMapFindChoice(
               M, Value, Start,
               (Start +Int End) /Int 2,
               asRangeMapItem(L[(Start +Int End) /Int 2]),
               End
          )
          requires Start <Int End -Int 1

     rule #rangeMapFindChoice(M:RangeMap, Value:Int, Start:Int, Middle:Int, rangeMapItem(MiddleStart:Int, _:Int), _End:Int)
          => #rangeMapFind(M, Value, Start, Middle)
          requires Value <Int MiddleStart
     rule #rangeMapFindChoice(M:RangeMap, Value:Int, _Start:Int, Middle:Int, rangeMapItem(MiddleStart:Int, _:Int), End:Int)
          => #rangeMapFind(M, Value, Middle, End)
          requires Value >=Int MiddleStart

     rule isInRangeMapItem(Value:Int, rangeMapItem(Start:Int, End:Int))
          => Start <=Int Value andBool Value <=Int End

     rule #checkInRangeMapItem(Value:Int, Item:RangeMapItem) => Item
          requires isInRangeMapItem(Value, Item)
     rule #checkInRangeMapItem(_:Int, _:RangeMapItem) => noRangeMapItem  [owise]

     rule #firstRangeMapItem(noRangeMapItem, Item:RangeMapItem) => Item
     rule #firstRangeMapItem(Item:RangeMapItem, _) => Item  [owise]

     rule asRangeMapItem(Item:RangeMapItem) => Item

     rule .RangeMap => rangeMap(.List)
     rule rangeMapAppendSorted(
               rangeMap(
                    (_::List ListItem(rangeMapItem(_:Int, LastEnd:Int))) #as L::List),
               rangeMapItem(Start:Int, End:Int) #as Item:RangeMapItem
          )
          => rangeMap(L ListItem(Item))
          requires LastEnd <Int Start andBool Start <=Int End

     rule mergeRangeMaps(First:RangeMap, Second:RangeMap)
          => #mergeRangeMaps(First, Second, .RangeMap)

     rule #mergeRangeMaps(rangeMap(.List), rangeMap(.List), Merged:RangeMap)
          => Merged
     rule #mergeRangeMaps(
               rangeMap(ListItem(rangeMapItem(Start:Int, End:Int) #as FirstItem) FirstRemainder:List),
               rangeMap(ListItem(rangeMapItem(Start:Int, End:Int)) SecondRemainder:List),
               Merged:RangeMap
          )
          => #mergeRangeMaps(
               rangeMap(FirstRemainder),
               rangeMap(SecondRemainder),
               rangeMapAppendSorted(Merged, FirstItem)
          )
     rule #mergeRangeMaps(
               rangeMap(ListItem(rangeMapItem(FirstStart:Int, _:Int) #as FirstItem) FirstRemainder:List),
               rangeMap(ListItem(rangeMapItem(SecondStart:Int, _:Int)) _:List) #as Second:RangeMap,
               Merged:RangeMap
          )
          => #mergeRangeMaps(
               rangeMap(FirstRemainder), Second,
               rangeMapAppendSorted(Merged, FirstItem)
          )
          requires FirstStart <Int SecondStart
     rule #mergeRangeMaps(
               rangeMap(ListItem(rangeMapItem(FirstStart:Int, _:Int)) _:List) #as First:RangeMap,
               rangeMap(ListItem(rangeMapItem(SecondStart:Int, _:Int) #as SecondItem) SecondRemainder:List),
               Merged:RangeMap
          )
          => #mergeRangeMaps(
               First, rangeMap(SecondRemainder),
               rangeMapAppendSorted(Merged, SecondItem)
          )
          requires FirstStart >Int SecondStart

endmodule
