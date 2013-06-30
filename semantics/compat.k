module COMPAT-SYNTAX
     syntax K ::= "l" "(" KLabel ")" [avoid]

     syntax String ::= firstChar(String) [function]
     syntax String ::= "nthChar" "(" String "," Int ")" [function]
     syntax String ::= "butFirstChar" "(" String ")" [function]
     
     syntax List ::= "stringToList" "(" String ")" [function]
     syntax String ::= listToString(List) [function]

     syntax String ::= toUpperCase(String) [function]


     syntax Bool ::= Bag "==Bag" Bag [function]
     syntax Bool ::= Bag "=/=Bag" Bag [function]

     syntax Bag ::= toBag(List) [function]
                | toBag(KList) [function]

     syntax Int ::= "lengthKList" KList [function]

     syntax Bool ::= BagItem "in" Bag [function]
               | K "#inBag" Bag [function]

     syntax KList ::= eraseKLabel(KLabel, KList) [function]

     syntax Int ::= "string2Base" "(" String "," Int ")"
          [function, klabel('string2Base), hook(#CONVERSION:string2Base)]
     syntax String ::= "base2String" "(" Int "," Int ")"
          [function, klabel('base2String), hook(#CONVERSION:base2String)]

     syntax Float ::= "sqrtFloat" "(" Float ")" 
          [function, hook(#FLOAT:sqrtFloat)]
     syntax Float ::= "logFloat" "(" Float ")" 
          [function, hook(#FLOAT:logFloat)]
     syntax Float ::= "expFloat" "(" Float ")" 
          [function, hook(#FLOAT:expFloat)]
     syntax Float ::= "atanFloat" "(" Float ")" 
          [function, hook(#FLOAT:atanFloat)]
     syntax Float ::= "acosFloat" "(" Float ")" 
          [function, hook(#FLOAT:acosFloat)]
     syntax Float ::= "asinFloat" "(" Float ")" 
          [function, hook(#FLOAT:asinFloat)]
     syntax Float ::= "tanFloat" "(" Float ")" 
          [function, hook(#FLOAT:tanFloat)]
     syntax Float ::= "cosFloat" "(" Float ")" 
          [function, hook(#FLOAT:cosFloat)]
     syntax Float ::= "sinFloat" "(" Float ")" 
          [function, hook(#FLOAT:sinFloat)]
     syntax Float ::= "atan2Float" "(" Float "," Float ")" 
          [function, hook(#FLOAT:atanFloat)]
     syntax Float ::= "floorFloat" "(" Float ")" 
          [function, hook(#FLOAT:floorFloat)]

     // TODO(chathhorn): ugly
     syntax K ::= "toKRList" "(" KList ")"
     syntax K ::= "toKRList'" "(" KList ")"

     syntax K ::= "toRVList" "(" KList ")"
     syntax K ::= "toRVList'" "(" KList ")"

     syntax KResult ::= "krlist" "(" KList ")"
     syntax KResult ::= "rvlist" "(" KList ")"

     syntax KList ::= reverseList(KList) [function]

     syntax ListItem ::= "ListItem" "(" Bag ")"
     syntax K ::= ListToK(List)
     syntax K ::= "map" "(" Map ")"

     syntax K ::= "klistToK" "(" KList ")" [function]
     
     syntax K ::= "kpair" "(" K "," K ")"

     syntax Bool ::= K "in" List [function]
     syntax "in" -/- [a-zA-Z]

     syntax KList ::= Int "to" Int [function]

endmodule

module C-COMPAT
     imports C-COMPAT-SYNTAX

     imports C-HELPERS-SYNTAX

     rule stringToList("") => .List
     rule stringToList(S:String)
               => ListItem(firstChar(S:String)) 
                    stringToList(butFirstChar(S:String))
          when S:String =/=String ""
          
     rule listToString(.List) => ""
     rule listToString((ListItem(S:String) L:List))
               => S:String +String listToString(L:List)

     rule [firstChar]:
          firstChar(S:String) => substrString(S:String, 0, 1)
          [structural]

     rule [nthChar]:
          nthChar(S:String, N:Int) => substrString(S:String, N:Int, 1)
          [structural]

     rule [butFirstChar]:
          butFirstChar(S:String) 
          => substrString(S:String, 1, lengthString(S:String))
          [structural]
          
     rule toUpperCase(S:String)
          => toUpperCase(firstChar(S:String))
               +String toUpperCase(butFirstChar(S:String))
          when lengthString(S) >Int 1

     rule toUpperCase(C:String)
          => C:String
          when (lengthString(C) ==Int 1)
               andBool (asciiString(C) <Int asciiString("a")
                    orBool asciiString(C) >Int asciiString("z"))
     rule toUpperCase(C:String)
          => #charString(absInt(asciiString(C) 
               -Int (asciiString("a") -Int asciiString("A"))))
          when (lengthString(C) ==Int 1)
               andBool (asciiString(C) >=Int asciiString("a")
                    andBool asciiString(C) <=Int asciiString("z"))
          
     // this should probably go in the k prelude
     rule K:K in (ListItem(K:K) _:List) => true
     rule _:K in .List => false
     rule K:K in (ListItem(K':K) L:List) => K:K in L:List
          when K:K =/=K K':K
          [structural]

     rule X:Bag ==Bag Y:Bag => Bag2KLabel X(.KList) ==K Bag2KLabel Y(.KList)
     rule X:Bag =/=Bag Y:Bag => notBool (X ==Bag Y)

     rule toBag(ListItem(K:K) L:List) => BagItem(K) toBag(L)
     rule toBag(.List) => .Bag

     rule toBag(K:K,, L:KList) => BagItem(K) toBag(L)
     rule toBag(.KList) => .Bag

     rule lengthKList (_:K,, L:KList) => 1 +Int lengthKList L
     rule lengthKList .KList => 0

     rule BagItem(K:K) in B:Bag => K #inBag B ==K true 
     rule K:K #inBag BagItem(K) _:Bag => true

     rule eraseKLabel(L:KLabel, L(Ks:KList)) => eraseKLabel(L, Ks)
     rule eraseKLabel(L:KLabel, L':KLabel(Ks:KList)) => L'(eraseKLabel(L, Ks))
          when L =/=KLabel L'
     rule eraseKLabel(L:KLabel, (K:K,,Ks:KList)) 
          => eraseKLabel(L, K),,eraseKLabel(L, Ks)
          when Ks =/=KList .KList
     rule eraseKLabel(_, .KList) => .KList
     rule eraseKLabel(_, .K) => .K

     rule klist(L:KList) => toKRList(L) 
          [structural]

     context toKRList'(_,, HOLE,, _)
     context toRVList'(_,, (HOLE => reval(HOLE)),, _) [ndheat]

     rule toKRList(L:KList) => toKRList'(L) ~> krlist(.KList)
          [structural]
     rule toRVList(L:KList) => toRVList'(L) ~> rvlist(.KList)
          [structural]

     rule toKRList'(_,, (V:KResult => .KList)) ~> krlist((.KList => V),, _) 
          [structural]

     rule toRVList'(_,, (V:KResult => .KList)) ~> rvlist((.KList => V),, _) 
          [structural]

     rule toKRList'(.KList) => .
          [structural]
     rule toRVList'(.KList) => .
          [structural]
     
     rule reverseList(.KList) => .KList
     rule reverseList((K:K,, L:KList)) => reverseList(L:KList),, K:K

	rule N:Int to N => .KList
	rule N:Int to N':Int => (N,,((N +Int 1) to N'))
		when N <Int N'
		[structural]

endmodule

