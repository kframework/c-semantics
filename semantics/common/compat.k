module COMPAT-SORTS
     syntax StrictList
     syntax StrictListResult
endmodule

module COMPAT-SYNTAX
     imports COMPAT-SORTS
     imports COMMON-SYNTAX

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

     syntax Bool ::= all(List, K) [function]
     syntax Bool ::= some(List, K) [function]

     syntax List ::= removeListItem(List, K) [function]

     syntax StrictListResult ::= krlist(List)
     syntax StrictList ::= StrictListResult
     syntax KResult ::= StrictListResult

     syntax List ::= reverseList(List) [function]

     syntax StrictList ::= list(List)
     syntax KItem ::= set(Set)

     syntax K ::= listToK(List) [function]
     syntax List ::= kSeqToList(K) [function]

     syntax KTuple ::= kpair(K, K)
                    | ktriple(K, K, K)

     syntax K ::= fst(KTuple) [function]
                | snd(KTuple) [function]

     syntax List ::= Int "to" Int [function]

     syntax List ::= times(Int, K) [function]

     syntax Set ::= filterSet(Set, K) [function]
     syntax List ::= filterList(List, K) [function]

     syntax Set ::= listToSet(List) [function]

     syntax Bool ::= some(Set, K) [function]
                   | some(Map, K) [function]

     syntax Int ::= ceilDiv(Int, Int) [function]
     syntax List ::= mapList(List, K) [function]
                   | flatMapList(List, K) [function]

     syntax SSList ::= toSSList(List) [function]
     syntax List ::= ofSSList(SSList) [function]
     syntax SList ::= toSList(List) [function]
     syntax List ::= ofSList(SList) [function]

     syntax KItem ::= seqstrict(StrictList)

     syntax Map ::= Map "[" K "," K "<-" K "]" [function]
     syntax Map ::= Map "[" K "+=" K "]" [function]
     syntax Map ::= Map "[" K "<+" Map "]" [function]
     syntax Bool ::= K "," K "in_keys" "(" Map ")" [function]

endmodule

module COMPAT
     imports COMPAT-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports BOOL
     imports MAP
     imports STRING

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
     rule showCId(X:UnnamedCId) => #showCId(X, #configuration)
     rule showCId(_::CId) => "<unknown>" [owise]

     syntax String ::= #showCId(CId, K) [function]
     rule #showCId(X::UnnamedCId, <generatedTop>... <unnamed-locs>... X |-> CabsLoc(File::String, _, Line::Int, _, _) ...</unnamed-locs> ...</generatedTop>)
          => "<anonymous at " +String File +String ":" +String showInt(Line) +String ">"
     rule #showCId(_, _) => "<unknown>" [owise]

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

     rule all(ListItem(K:KItem) L:List, #klabel(Lbl:KLabel))
          => Lbl(K) andBool all(L, #klabel(Lbl))
     rule all(.List, _) => true

     rule some(ListItem(K:KItem) L:List, #klabel(Lbl:KLabel))
          => Lbl(K) orBool some(L, #klabel(Lbl))
     rule some(.List, _) => false

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

     syntax KItem ::= "seqstrict()"
     rule seqstrict(list(HOLE:List)) => toSSList(HOLE) ~> seqstrict() [heat]
     rule HOLE:SSList ~> seqstrict() => seqstrict(krlist(ofSSList(HOLE))) [cool]

     syntax SSList ::= K "seqstrict::" SSList [seqstrict]
                     | ".SSList"
     rule isKResult(.SSList) => true
     rule isKResult(S1::SSList seqstrict:: S2::SSList) => isKResult(S1) andBool isKResult(S2)
     rule toSSList(ListItem(K:KItem) L::List) => K seqstrict:: toSSList(L)
     rule toSSList(.List) => .SSList
     rule ofSSList(krlist(L1::List) seqstrict:: L2::SSList) => L1 ofSSList(L2)
     rule ofSSList(.SSList) => .List
     rule ofSSList(K:K seqstrict:: L::SSList) => ListItem(K) ofSSList(L) [owise]

     syntax KItem ::= "strict()"
     rule list(HOLE:List) => toSList(HOLE) ~> strict() [heat]
     rule HOLE:SList ~> strict() => krlist(ofSList(HOLE)) [cool]

     syntax SList ::= K "strict::" SList [strict]
                    | ".SList"
     rule isKResult(.SList) => true
     rule isKResult(S1::SList strict:: S2::SList) => isKResult(S1) andBool isKResult(S2)
     rule toSList(ListItem(K:KItem) L::List) => K strict:: toSList(L)
     rule toSList(.List) => .SList
     rule ofSList(krlist(L1::List) strict:: L2::SList) => L1 ofSList(L2)
     rule ofSList(.SList) => .List
     rule ofSList(K:K strict:: L::SList) => ListItem(K) ofSList(L) [owise]

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
     rule times(N:Int, K:K) => ListItem(K) times(N -Int 1, K)
          requires N >Int 0

     rule filterSet(SetItem(K:KItem) S:Set, #klabel(Pred:KLabel))
          => #filterSet(K, S, #klabel(Pred))
     rule filterSet(.Set, _)
          => .Set

     syntax Set ::= #filterSet(K, Set, K) [function]
     rule #filterSet(K:K, .Set, #klabel(Pred:KLabel))
          => SetItem(K)
          requires Pred(K) ==K true
     rule #filterSet(K:K, .Set, #klabel(Pred:KLabel))
          => .Set
          requires Pred(K) =/=K true
     rule #filterSet(K:K, SetItem(K':KItem) S:Set, #klabel(Pred:KLabel))
          => SetItem(K) #filterSet(K', S, #klabel(Pred))
          requires Pred(K) ==K true
     rule #filterSet(K:K, SetItem(K':KItem) S:Set, #klabel(Pred:KLabel))
          => #filterSet(K', S, #klabel(Pred))
          requires Pred(K) =/=K true

     rule filterList(ListItem(K:KItem) L:List, #klabel(Pred:KLabel))
          => #filterList(K, L, #klabel(Pred))
     rule filterList(.List, _)
          => .List

     syntax List ::= #filterList(K, List, K) [function]
     rule #filterList(K:K, .List, #klabel(Pred:KLabel))
          => ListItem(K)
          requires Pred(K) ==K true
     rule #filterList(K:K, .List, #klabel(Pred:KLabel))
          => .List
          requires Pred(K) =/=K true
     rule #filterList(K:K, ListItem(K':KItem) L:List, #klabel(Pred:KLabel))
          => ListItem(K) #filterList(K', L, #klabel(Pred))
          requires Pred(K) ==K true
     rule #filterList(K:K, ListItem(K':KItem) L:List, #klabel(Pred:KLabel))
          => #filterList(K', L, #klabel(Pred))
          requires Pred(K) =/=K true

     rule listToSet(ListItem(K:KItem) Tail::List) => SetItem(K) listToSet(Tail)
     rule listToSet(.List) => .Set

     rule some(S:Set, Lbl:K) => some'(.K, S, Lbl)

     syntax Bool ::= "some'" "(" K "," Set "," K ")" [function]
     rule some'(.K, SetItem(K:KItem) S:Set, Lbl:K) => some'(K, S, Lbl)
     rule some'(K:K, _, #klabel(Lbl:KLabel)) => true
          requires Lbl(K) ==K true
     rule some'(K:K, S:Set, #klabel(Lbl:KLabel)) => some'(.K, S, #klabel(Lbl))
          requires Lbl(K) =/=K true
               andBool (K =/=K .K)
     rule some'(.K, .Set, _) => false

     rule some(.Map::Map, Lbl:K) => false
     rule some(K1:KItem |-> K2:KItem M::Map, #klabel(Lbl:KLabel)) => Lbl(K1, K2) orBool some(M, #klabel(Lbl)) [owise]

     rule ceilDiv(X:Int, Y:Int) => (X +Int Y -Int 1) /Int Y

     rule mapList(ListItem(K:KItem) L:List, #klabel(Lbl:KLabel)) => ListItem(Lbl(K)) mapList(L, #klabel(Lbl))
     rule mapList(.List, _) => .List
     rule flatMapList(ListItem(K:KItem) L:List, #klabel(Lbl:KLabel)) => {Lbl(K)}:>List flatMapList(L, #klabel(Lbl))
     rule flatMapList(.List, _) => .List

     rule ((A |-> S::Set) M::Map) [A:K += B:K] => (A |-> (S SetItem(B))) M
     rule M::Map [A:K += B:K] => M A |-> SetItem(B) [owise]

     rule ((A |-> M2::Map) M1::Map) [A:K <+ B::Map] => (A |-> (M2 B)) M1
     rule M::Map [A:K <+ B::Map] => M A |-> B [owise]

     rule fst(kpair(K:K, _)) => K
     rule snd(kpair(_, K:K)) => K
endmodule
