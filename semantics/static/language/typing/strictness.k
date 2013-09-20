module C-TYPING-STRICTNESS-SYNTAX
     syntax K ::= "evalToType"

endmodule

module C-TYPING-STRICTNESS
     imports C-TYPING-STRICTNESS-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-SYNTAX
     imports COMPAT-SYNTAX

     syntax K ::= "waitingOnDeclType"
     rule [type-Cast-heat]:
          <k> (. => DeclType(Spec, Decl)) ~> evalToType ...</k>
          <type> 
               Cast(Spec:K, Decl:K, _) => waitingOnDeclType
          ...</type>
          [structural]
          
     rule [type-Cast-cool]:
          <k> (T:KResult => .) ~> evalToType ...</k>
          <type> waitingOnDeclType => T:KResult ...</type>
          [structural]


     // chathhorn: hacky custom heating/cooling for type-strictness.
     syntax Set ::= "typeStrictUnaryOps" [function]
               | "typeStrictBinaryOps" [function]
               | "typeStrictBinaryOpsFirst" [function]
               | "typeStrictBinaryOpsSecond" [function]
               | "typeStrictTernaryOpsSecond" [function]
               | "typeStrictTernaryOpsThird" [function]

     rule typeStrictUnaryOps =>
          SetItem(l('-_))
          SetItem(l('+_))
          SetItem(l('!_))
          SetItem(l('~_))
          SetItem(l('*_))
          SetItem(l('&_))
          SetItem(l('++_))
          SetItem(l('--_))
          SetItem(l('_++))
          SetItem(l('_--))

     rule typeStrictBinaryOps =>
          SetItem(l('_*_))
          SetItem(l('_/_))
          SetItem(l('_%_))
          SetItem(l('_+_))
          SetItem(l('_-_))
          SetItem(l('_<_))
          SetItem(l('_<=_))
          SetItem(l('_>_))
          SetItem(l('_>=_))
          SetItem(l('_==_))
          SetItem(l('_!=_))
          SetItem(l('_&_))
          SetItem(l('_^_))
          SetItem(l('_|_))
          SetItem(l('_&&_))
          SetItem(l('_||_))
          SetItem(l('_`[_`]))

     rule typeStrictBinaryOpsFirst =>
          typeStrictBinaryOps
          SetItem(l('_<<_))
          SetItem(l('_>>_))
          SetItem(l('_*=_))
          SetItem(l('_/=_))
          SetItem(l('_%=_))
          SetItem(l('_+=_))
          SetItem(l('_-=_))
          SetItem(l('_<<=_))
          SetItem(l('_&=_))
          SetItem(l('_^=_))
          SetItem(l('_|=_))
          SetItem(l('_>>=_))
          SetItem(l('_:=_))
          SetItem(l('Call))
          SetItem(l('_._))

     rule typeStrictBinaryOpsSecond =>
          typeStrictBinaryOps

     rule typeStrictTernaryOpsSecond =>
          SetItem(l('_?_:_))

     rule typeStrictTernaryOpsThird =>
          SetItem(l('_?_:_))

     syntax K ::= "THOLE"

     rule <type>
               Lbl:KLabel(K:K) => K ~> Lbl(THOLE)
          ...</type>
          when l(Lbl) in typeStrictUnaryOps
               andBool (getKLabel(K) =/=KLabel 't)
               andBool (K =/=K THOLE)
          [structural]
     rule <type>
               R:Type ~> Lbl:KLabel(THOLE) => Lbl(R)
          ...</type>
          when l(Lbl) in typeStrictUnaryOps
          [structural]

     rule <type>
               Lbl:KLabel(K:K,, X:K) => K ~> Lbl(THOLE,, X)
          ...</type>
          when l(Lbl) in typeStrictBinaryOpsFirst
               andBool (getKLabel(K) =/=KLabel 't)
               andBool (K =/=K THOLE)
          [structural]
     rule <type>
               Lbl:KLabel(X:K,, K:K) => K ~>  Lbl(X,, THOLE)
          ...</type>
          when l(Lbl) in typeStrictBinaryOpsSecond
               andBool (getKLabel(K) =/=KLabel 't)
               andBool (K =/=K THOLE)
          [structural]
     rule <type>
               R:Type ~> Lbl:KLabel(THOLE,, X:K) => Lbl(R,, X)
          ...</type>
          when l(Lbl) in typeStrictBinaryOpsFirst
          [structural]
     rule <type>
               R:Type ~> Lbl:KLabel(X:K,, THOLE) => Lbl(X,, R)
          ...</type>
          when l(Lbl) in typeStrictBinaryOpsSecond
          [structural]

     rule <type>
               Lbl:KLabel(X:K,, K:K,, Y:K) => K ~> Lbl(X,, THOLE,, Y)
          ...</type>
          when l(Lbl) in typeStrictTernaryOpsSecond
               andBool (getKLabel(K) =/=KLabel 't)
               andBool (K =/=K THOLE)
          [structural]
     rule <type>
               Lbl:KLabel(X:K,, Y:K,, K:K) => K ~> Lbl(X,, Y,, THOLE)
          ...</type>
          when l(Lbl) in typeStrictTernaryOpsThird
               andBool (getKLabel(K) =/=KLabel 't)
               andBool (K =/=K THOLE)
          [structural]
     rule <type>
               R:Type ~> Lbl:KLabel(X:K,, THOLE,, Y:K) => Lbl(X,, R,, Y)
          ...</type>
          when l(Lbl) in typeStrictTernaryOpsSecond
          [structural]
     rule <type> 
               R:Type ~> Lbl:KLabel(X:K,, Y:K,, THOLE) => Lbl(X,, Y,, R)
          ...</type>
          when l(Lbl) in typeStrictTernaryOpsThird
          [structural]

endmodule
