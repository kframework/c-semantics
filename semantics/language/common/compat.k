module COMPAT-SYNTAX
     //TODO: must not need the second one
     syntax KItem ::= l(KLabel) [avoid]
     syntax KItem ::= klist(KList) [function]

     syntax String ::= firstChar(String) [function]
     syntax String ::= nthChar(String, Int) [function]
     syntax String ::= butFirstChar(String) [function]
     
     syntax List ::= stringToList(String) [function]
     syntax String ::= listToString(List) [function]

     syntax String ::= idToString(CId) [function]

     syntax String ::= toUpperCase(String) [function]

     syntax Bool ::= all(List, KLabel) [function]

     //TODO: this might be able to remove
     syntax Bool ::= isAllKResultInHeatList(HeatList) [function]

     syntax Bool ::= List "==MSet" List [function]
		   | List "=/=MSet" List [function]
		   | K "in" List [function]

     syntax List ::= removeListItem(List,K) [function]

     syntax Float ::= sqrtFloat(Float) [function]
     syntax Float ::= logFloat(Float)
          [function, hook(#FLOAT:log)]
     syntax Float ::= expFloat(Float)
          [function, hook(#FLOAT:exp)]
     syntax Float ::= atanFloat(Float)
          [function, hook(#FLOAT:atan)]
     syntax Float ::= acosFloat(Float)
          [function, hook(#FLOAT:acos)]
     syntax Float ::= asinFloat(Float)
          [function, hook(#FLOAT:asin)]
     syntax Float ::= tanFloat(Float)
          [function, hook(#FLOAT:tan)]
     syntax Float ::= cosFloat(Float)
          [function, hook(#FLOAT:cos)]
     syntax Float ::= sinFloat(Float)
          [function, hook(#FLOAT:sin)]
     syntax Float ::= atan2Float(Float, Float)
          [function, hook(#FLOAT:atan)]
     syntax Float ::= floorFloat(Float)
          [function, hook(#FLOAT:floor)]

     // TODO(chathhorn): ugly
     syntax KItem ::= toKRList(List)

     syntax KResult ::= krlist(List)

     syntax List ::= reverseList(List) [function]

     //TODO: syntax List ::= ListItem(Bag)
     syntax KItem ::= bag2K(Bag)
     syntax KItem ::= list(List)
     syntax KItem ::= map(Map)
     syntax KItem ::= set(Set)

     syntax KItem ::= listToK(List)
     
     syntax KItem ::= kpair(K, K)

     syntax KList ::= Int "to" Int [function]
     //TODO: make sure this is in current including List syntax Bool ::= K "in" List [function]
     syntax "in" -/- [a-zA-Z]

     syntax List ::= times(Int, K) [function]

     // syntax Int ::= lengthList(List) [function]

     //syntax Map ::= Map "[" K "<-" K "]"
     //rule M:Map[Val:K <- Key:K] => M[Val/Key] [macro]

     //syntax List ::= values(Map) [function]

     syntax Set ::= filterSet(Set, KLabel) [function]
endmodule

module COMPAT
     imports COMPAT-SYNTAX
     imports C-SYNTAX // Would like to get rid of this.

     rule sqrtFloat(F:Float) => rootFloat(F,2)

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
     rule K:K in (ListItem(K:K) _:List) => true
     rule _:K in .List => false
     rule K:K in (ListItem(K':K) L:List) => K:K in L:List
          when K:K =/=K K':K

     rule removeListItem(.List,_:K) => .List
     rule removeListItem(ListItem(A:K) M:List,A) => M
     rule removeListItem(ListItem(A:K) M:List,A':K) 
	=> ListItem(A) removeListItem(M,A')
	when A =/=K A'

     rule K:K in .List => false
     rule K:K in ListItem(K:K) _:List => true
     rule K:K in ListItem(K1:K) L:List => K in L when K =/=K K1

     rule '_==MSet_(.List ,, .List) => true
     rule '_==MSet_(.List ,, ListItem(_) _:List) => false
     rule '_==MSet_(ListItem(_) _:List ,, .List) => false
     rule '_==MSet_(ListItem(K:K) M:List ,, M':List) 
		=> '_==MSet_(M:List ,, removeListItem(M',K))
	  when K:K in M':List
     rule '_==MSet_(ListItem(K:K) _:List ,, M':List) 
		=> false
	  when notBool (K:K in M':List)

     rule M:List =/=MSet M':List => notBool '_==MSet_(M ,, M')

     rule list(L:List) => toKRList(L) 
          [structural]

     syntax KItem ::= "toKRList'" "(" SubKRList ")" [strict]

     //might not need this after accosicate matching 
     syntax SubKRItem ::= sItem(K) [strict]
     syntax SubKRList ::= List{SubKRItem,"ss::"} [strict]
     syntax SubKRList ::= toSubKRList(List) [function]

     syntax SubResult ::= srItem(K)
     syntax SubKRItem ::= SubResult
     syntax KResult ::= SubResult

     rule toSubKRList(.List) => .SubKRList
     rule toSubKRList(ListItem(K:K) L:List) => sItem(K) ss:: toSubKRList(L)

     //TODO: overcome the context associative matching
     //context toKRList'(_:List ListItem(HOLE) _:List)
     rule sItem(V:KResult) => srItem(V) [structural]

     rule toKRList(L:List) => toKRList'(toSubKRList(L)) ~> krlist(.List)
          [structural]

     rule toKRList'((srItem(V:KResult) ss:: S:SubKRList) => S) 
          ~> krlist(_:List (.List => ListItem(V))) 
          when getKLabel(V) =/=KLabel 'krlist
          [structural]
     // Somewhat contrived feature: nested lists are flattened.
     rule toKRList'((srItem(krlist(L:List)) ss:: S:SubKRList) => S) 
          ~> krlist( _:List (.List => L)) 
          [structural]
     rule toKRList'(.SubKRList) => .
          [structural]
     
     rule reverseList(.List) => .List
     rule reverseList(ListItem(K:K) L:List)
          => reverseList(L:List) ListItem(K:K)

     rule listToK(ListItem(K:K) L:List) => K ~> listToK(L) [structural]
     rule listToK(.List) => .K [structural]

     rule N:Int to N => .KList
     rule N:Int to N':Int => (N,, ((N +Int 1) to N'))
          when N <Int N'

     rule times(0, _) => .List
     rule times(N:Int, K:K) => ListItem(K) times(N -Int 1, K)
          when N >Int 0

     syntax List ::= klistToList(KList) [function]

     rule klistToList((K:K,, L:KList)) => ListItem(K) klistToList(L)
     rule klistToList(.KList) => .List

     rule 'klist(L:KList) => 'list(klistToList(L))

     // rule lengthList(L:List) => size(L)

     //rule values((_ |-> V:K) M:Map) => ListItem(V) values(M)
     //rule values(.Map) => .List

     syntax Set ::= #filterSet(K,Set,KLabel) [function]

     rule #filterSet(K:K,.Set,Pred:KLabel)
	  => SetItem(K:K)
	  when Pred(K:K) ==K true
     rule #filterSet(K:K,.Set,Pred:KLabel)
	  => .Set 
          when Pred(K:K) =/=K true
     rule #filterSet(K:K,SetItem(K':K) S:Set,Pred:KLabel)
	  => SetItem(K) #filterSet(K',S,Pred)
	  when Pred(K:K) ==K true
     rule #filterSet(K:K,SetItem(K':K) S:Set,Pred:KLabel)
	  => #filterSet(K',S,Pred)
          when Pred(K:K) =/=K true

     rule filterSet(SetItem(K:K) S:Set, Pred:KLabel)
          => #filterSet(K,S,Pred)

     //TODO: might be able to remove later
     rule isAllKResultInHeatList(.HeatList) => true
     rule isAllKResultInHeatList(hItem(K:K) hs:: _:HeatList) => false
	   when isKResult(K:K) =/=K true
     rule isAllKResultInHeatList(hItem(K:K) hs:: HL:HeatList) 
	   => isAllKResultInHeatList(HL) 
	   when isKResult(K:K) ==K true

endmodule
