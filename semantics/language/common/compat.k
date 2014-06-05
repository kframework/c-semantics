module COMPAT-SYNTAX
     syntax KItem ::= l(KLabel) [avoid]
     syntax KItem ::= klist(KList) [klabel('klist)]

     syntax String ::= firstChar(String) [function]
     syntax String ::= nthChar(String, Int) [function]
     syntax String ::= butFirstChar(String) [function]
     
     syntax List ::= stringToList(String) [function]
     syntax String ::= listToString(List) [function]

     syntax String ::= idToString(CId) [function]

     syntax String ::= toUpperCase(String) [function]

     syntax Bool ::= all(List, KLabel) [function]
   
     syntax MSet ::= List{MSetItem,""}
     syntax MSetItem ::= MSetItem(K)

     syntax Bool ::= MSet "==MSet" MSet [function]
		   | MSet "=/=MSet" MSet [function]
		   | K "in" MSet [function]

     syntax MSet ::= toMSet(List) [function]

     /*TODO: Bag does not work in Java backend
	syntax Bool ::= Bag "==Bag" Bag [function]
     syntax Bool ::= Bag "=/=Bag" Bag [function]
	*/

     //Do not need this and java backend does not support Bag function 
     //syntax Bag ::= toBag(List) [function]

    /*TODO: Bag
     syntax Bool ::= BagItem "in" Bag [function]
                   | K "#inBag" Bag [function]
    */

     syntax Int ::= string2Base(String, Int)
          [function, klabel('string2Base), hook(#CONVERSION:string2Base)]
     syntax String ::= base2String(Int, Int)
          [function, klabel('base2String), hook(#CONVERSION:base2String)]

     syntax Float ::= sqrtFloat(Float)
          [function, hook(#FLOAT:sqrtFloat)]
     syntax Float ::= logFloat(Float)
          [function, hook(#FLOAT:logFloat)]
     syntax Float ::= expFloat(Float)
          [function, hook(#FLOAT:expFloat)]
     syntax Float ::= atanFloat(Float)
          [function, hook(#FLOAT:atanFloat)]
     syntax Float ::= acosFloat(Float)
          [function, hook(#FLOAT:acosFloat)]
     syntax Float ::= asinFloat(Float)
          [function, hook(#FLOAT:asinFloat)]
     syntax Float ::= tanFloat(Float)
          [function, hook(#FLOAT:tanFloat)]
     syntax Float ::= cosFloat(Float)
          [function, hook(#FLOAT:cosFloat)]
     syntax Float ::= sinFloat(Float)
          [function, hook(#FLOAT:sinFloat)]
     syntax Float ::= atan2Float(Float, Float)
          [function, hook(#FLOAT:atanFloat)]
     syntax Float ::= floorFloat(Float)
          [function, hook(#FLOAT:floorFloat)]

     // TODO(chathhorn): ugly
     syntax KItem ::= toKRList(List)

     syntax KResult ::= krlist(List) [klabel('krlist)]

     syntax List ::= reverseList(List) [function]

     //TODO: syntax List ::= ListItem(Bag)
     syntax KItem ::= bag2K(Bag)
     syntax KItem ::= list(List)
     syntax KItem ::= map(Map)
     syntax KItem ::= set(Set)

     syntax KItem ::= listToK(List) [function]
     
     syntax KItem ::= kpair(K, K)

     syntax KList ::= Int "to" Int [function]
     //TODO: make sure this is in current including List syntax Bool ::= K "in" List [function]
     syntax "in" -/- [a-zA-Z]

     syntax List ::= times(Int, K) [function]

     // syntax Int ::= lengthList(List) [function]

     //syntax Map ::= Map "[" K "<-" K "]"
     //rule M:Map[Val:K <- Key:K] => M[Val/Key] [macro]

     syntax List ::= values(Map) [function]

     syntax Set ::= filterSet(Set, KLabel) [function]
endmodule

module COMPAT
     imports COMPAT-SYNTAX
     imports C-SYNTAX // Would like to get rid of this.

     rule stringToList("") => .List
     rule stringToList(S:String)
               => ListItem(firstChar(S:String)) 
                    stringToList(butFirstChar(S:String))
          when S:String =/=String ""
          
     rule listToString(.List) => ""
     rule listToString((ListItem(S:String) L:List))
               => S:String +String listToString(L:List)

     rule idToString(Identifier(S:String)) => S

     rule [firstChar]:
          firstChar(S:String) => substrString(S, 0, 1)

     rule [nthChar]:
          nthChar(S:String, N:Int) => substrString(S, N, N +Int 1)

     rule [butFirstChar]:
          butFirstChar(S:String) 
          => substrString(S:String, 1, lengthString(S:String))

     rule all(ListItem(K:K) L:List, Lbl:KLabel) 
          => Lbl(K:K) andBool all(L, Lbl)
     rule all(.List, _) => true 
          
     rule toUpperCase(S:String)
          => toUpperCase(firstChar(S:String))
               +String toUpperCase(butFirstChar(S:String))
          when lengthString(S) >Int 1

     rule toUpperCase(C:String)
          => C:String
          when (lengthString(C) ==Int 1)
               andBool (ordChar(C) <Int ordChar("a")
                    orBool ordChar(C) >Int ordChar("z"))
     rule toUpperCase(C:String)
          => chrChar(absInt(ordChar(C) 
               -Int (ordChar("a") -Int ordChar("A"))))
          when (lengthString(C) ==Int 1)
               andBool (ordChar(C) >=Int ordChar("a")
                    andBool ordChar(C) <=Int ordChar("z"))
          
     // this should probably go in the k prelude
     //rule K:K in (ListItem(K:K) _:List) => true
     //rule _:K in .List => false
     //rule K:K in (ListItem(K':K) L:List) => K:K in L:List
         // when K:K =/=K K':K

/*TODO: runtime exception TODO Support ==Bag: Might need to support multiset equivalence
     syntax Bool ::= midMakeEqual(Bag,Bag,Bag, K) [function]


     rule midMakeEqual(B:Bag,B':Bag,.Bag,_:K) => B ==Bag B'
     rule midMakeEqual(B:Bag,B':Bag,BagItem(A:K) B'':Bag,A) => B ==Bag (B' B'')
     rule midMakeEqual(B:Bag,B':Bag,BagItem(A:K) B'':Bag,A':K) 
		=> midMakeEqual(B,BagItem(A:K) B',B'',A') 
	 when A =/=K A'
 
     rule .Bag ==Bag .Bag => true 
     rule _:BagItem _:Bag ==Bag .Bag => false
     rule .Bag ==Bag _:BagItem _:Bag => false
     rule BagItem(K:K) B:Bag ==Bag B':Bag => midMakeEqual(B,.Bag,B',K)
	 when BagItem(K) in B':Bag
     rule BagItem(K:K) _:Bag ==Bag B':Bag => false
	 when notBool (BagItem(K) in B':Bag)


     rule X:Bag =/=Bag Y:Bag => notBool (X ==Bag Y)
      rule X:Bag =/=Bag Y:Bag => (X =Bag Y) =/=K true

     rule toBag(ListItem(K:K) L:List) => BagItem(K) toBag(L)
     rule toBag(.List) => .Bag

     rule BagItem(K:K) in B:Bag => K #inBag B ==K true 
     rule K:K #inBag BagItem(K) _:Bag => true
*/
     syntax MSet ::= removeMSetItem(MSet,K)
     
     rule removeMSetItem(.MSet,K:K) => .MSet
     rule removeMSetItem(MSetItem(K:K) M:MSet,K) => M
     rule removeMSetItem(MSetItem(A:K) M:MSet,A':K) 
	=> MSetItem(A) removeMSetItem(M,A')
	when A =/=K A'

     rule .MSet ==MSet .Mset => true
     rule .MSet ==MSet MI:MSetItem M:MSet => false
     rule MI:MSetItem M:MSet ==MSet .Mset => false
     rule MSetItem(K:K) M:MSet ==MSet M':MSet 
		=> M ==MSet removeMSetItem(M',K)

     rule M:MSet =/=MSet M':MSet => notBool (M ==MSet M')

     rule toMSet(ListItem(K:K) L:List) => MSetItem(K) toMSet(L)
     rule toMSet(.List) => .MSet

     rule list(L:List) => toKRList(L) 
          [structural]

     syntax KItem ::= "toKRList'" "(" List ")"
     //TODO: overcome the context associative matching
     //context toKRList'(_:List ListItem(HOLE) _:List)
     rule toKRList(L:List) => toKRList'(L) ~> krlist(.List)
          [structural]
     rule toKRList'(_:List (ListItem(V:KResult) => .List)) 
          ~> krlist((.List => ListItem(V)) _:List) 
          when getKLabel(V) =/=KLabel 'krlist
          [structural]
     // Somewhat contrived feature: nested lists are flattened.
     rule toKRList'(_:List (ListItem(krlist(L:List)) => .List)) 
          ~> krlist((.List => L) _:List) 
          [structural]
     rule toKRList'(.List) => .
          [structural]
     
     rule reverseList(.List) => .List
     rule reverseList(ListItem(K:K) L:List)
          => reverseList(L:List) ListItem(K:K)

     rule listToK(ListItem(K:K) L:List) => K ~> listToK(L)
     rule listToK(.List) => .K

     rule N:Int to N => .KList
     rule N:Int to N':Int => (N,, ((N +Int 1) to N'))
          when N <Int N'

     rule times(0, _) => .List
     rule times(N:Int, K:K) => ListItem(K) times(N -Int 1, K)
          when N >Int 0

     syntax List ::= klistToList(KList) [function]

     rule klistToList((K:K,, L:KList)) => ListItem(K) klistToList(L)
     rule klistToList(.KList) => .List

     rule klist(L:KList) => list(klistToList(L))
          [structural, anywhere]

     // rule lengthList(L:List) => size(L)

     rule values((_ |-> V:K) M:Map) => ListItem(V) values(M)
     rule values(.Map) => .List

     rule filterSet(SetItem(K:K) S:Set, Pred:KLabel)
          => SetItem(K) filterSet(S, Pred)
          when Pred(K) ==K true
     rule filterSet(SetItem(K:K) S:Set, Pred:KLabel)
          => filterSet(S, Pred)
          when Pred(K) =/=K true
     rule filterSet(.Set, _) => .Set

endmodule

