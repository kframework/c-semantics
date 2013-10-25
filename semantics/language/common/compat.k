module COMPAT-SYNTAX
     syntax K ::= "l" "(" KLabel ")" [avoid]
     // hybrid doesn't work with list operator, and strict doesn't do what's
     // expected
     syntax K ::= "klist" "(" KList ")" [klabel('klist)]

     syntax String ::= firstChar(String) [function]
     syntax String ::= "nthChar" "(" String "," Int ")" [function]
     syntax String ::= "butFirstChar" "(" String ")" [function]
     
     syntax List ::= "stringToList" "(" String ")" [function]
     syntax String ::= listToString(List) [function]

     syntax String ::= toUpperCase(String) [function]

     syntax Bool ::= "all" "(" KList "," KLabel ")" [function]

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

     syntax KResult ::= "krlist" "(" KList ")"

     syntax KList ::= reverseList(KList) [function]

     syntax ListItem ::= "ListItem" "(" Bag ")"
     syntax K ::= ListToK(List)
     syntax K ::= "map" "(" Map ")"

     syntax K ::= "klistToK" "(" KList ")" [function]
     
     syntax K ::= "kpair" "(" K "," K ")"

     syntax Bool ::= K "in" List [function]
     syntax "in" -/- [a-zA-Z]

     syntax KList ::= Int "to" Int [function]

     syntax KList ::= times(Int, K) [function]

     // syntax K ::= writeConfig(String)
                // | readConfig(String)

     // TODO(chathhorn): better place for this?
     syntax K ::= case(Int)

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

     rule [firstChar]:
          firstChar(S:String) => substrString(S, 0, 1)

     rule [nthChar]:
          nthChar(S:String, N:Int) => substrString(S, N, N +Int 1)

     rule [butFirstChar]:
          butFirstChar(S:String) 
          => substrString(S:String, 1, lengthString(S:String))

     rule all((K:K,, L:KList), Lbl:KLabel) 
          => Lbl(K) andBool all(L, Lbl)
     rule all(.KList, _) => true 
          
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

     syntax K ::= "toKRList'" "(" KList ")"
     context toKRList'(_,, HOLE,, _)
     rule toKRList(L:KList) => toKRList'(L) ~> krlist(.KList)
          [structural]
     rule toKRList'(_,, (V:KResult => .KList)) ~> krlist((.KList => V),, _) 
          [structural]
     rule toKRList'(.KList) => .
          [structural]
     
     rule reverseList(.KList) => .KList
     rule reverseList((K:K,, L:KList)) => reverseList(L:KList),, K:K

	rule N:Int to N => .KList
	rule N:Int to N':Int => (N,,((N +Int 1) to N'))
		when N <Int N'

     rule klistToK((K:K,, L:KList)) => K ~> klistToK(L)
     rule klistToK(.KList) => .K

     rule times(0, _) => .KList
     rule times(N:Int, K:K) => (K,, times(N -Int 1, K))
          when N >Int 0

     // Read/write the current configuration.
     // syntax K ::= saveConfiguration(Int, String) 
               //  | loadConfiguration(Int, String) 
               //  | loadConfigurationByte(K)

     // rule <exec>
     //           <global> B:Bag </global>
     //           <k> 
     //                writeConfig(F:String) 
     //                => saveConfiguration(#open(F), K2String(CompiledProgram(B))) 
     //           ...</k>
     //      ...</exec>

     // rule (. => #write(Fd, substrString(S, 0, 1000))) 
     //      ~> saveConfiguration(Fd:Int, 
     //           (S:String => substrString(S, 1000, lengthString(S)))) 
     //      when S =/=String ""

     // syntax K ::= fuzz(String)

     // rule (. => #write(Fd, S)  ~> fuzz(S))
     //      ~> saveConfiguration(Fd:Int, (S:String => "")) 
     //      when S =/=String ""

     // rule saveConfiguration(Fd:Int, "") => #close(Fd)

     // rule readConfig(F:String) 
     //      => loadConfiguration(#open(F, "r"), "")
     // rule (. => loadConfigurationByte(#read(Fd, 1000))) 
     //      ~> loadConfiguration(Fd:Int, _)
     // rule (loadConfigurationByte(S2:String) => .) 
     //      ~> loadConfiguration(_, (S:String => S +String S2))
     // rule loadConfigurationByte(#EOF) ~> loadConfiguration(Fd:Int, S:String) 
     //      => #close(Fd) ~> doLoadConfiguration(String2Bag(S))
endmodule

