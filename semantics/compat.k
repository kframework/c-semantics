module C-COMPAT-SYNTAX
     imports C-SYNTAX 

     syntax K ::= "l" "(" KLabel ")" [avoid]

     syntax Bool ::= Bag "==Bag" Bag [function]
     syntax Bool ::= Bag "=/=Bag" Bag [function]

     syntax Bag ::= toBag(List) [function]
                | toBag(KList) [function]

     syntax Int ::= "lengthKList" KList [function]

     syntax Bool ::= BagItem "in" Bag [function]
               | K "#inBag" Bag [function]

     syntax KList ::= eraseKLabel(KLabel, KList) [function]

     syntax Bits ::= right:
                    "~Bits" Bits
                    [function, right, latex(\mathop{\sim_{\scriptstyle\it Bits}}{#1})]
                    > left:
                    Bits "/Bits" Bits
                    [function, left, latex({#1}\mathrel{\div_{\scriptstyle\it Bits}}{#2})]
                    > left:
                    Bits "&Bits" Bits
                    [function, left, latex({#1}\mathrel{\&_{\scriptstyle\it Bits}}{#2})]
                    > left:
                    Bits "xorBits" Bits
                    [function, left, latex({#1}\mathrel{\oplus_{\scriptstyle\it Bits}}{#2})]
                    > left:
                    Bits "|Bits" Bits
                    [function, left, latex({#1}\mathrel{|_{\scriptstyle\it Bits}}{#2})]

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
	rule N:Int to N' => (N,,((N +Int 1) to N'))
		when N <Int N'
		[structural]

endmodule

