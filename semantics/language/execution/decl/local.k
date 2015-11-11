module C-DECL-LOCAL
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     rule <k> declareInternalVariable(X:CId, T:Type, _:NoInit)
               => addToEnv(X, Base)
               ~> giveType(X, T')
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <external-defs>...
               X |-> Base:SymBase
          ...</external-defs>
          <external-types>...
               X |-> T':Type
          ...</external-types>
          requires isExternType(T) orBool isFunctionType(T)
          [structural]
     rule <k> declareInternalVariable(X:CId, T:Type, _:NoInit)
               => giveType(X, T)
          ...</k>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <external-defs> Defs:Map </external-defs>
          <external-types> Types:Map </external-types>
          requires isExternType(T) orBool isFunctionType(T)
               andBool notBool X in_keys(Defs)
               andBool notBool X in_keys(Types)
          [structural]
     rule <k> declareInternalVariable(X:CId, T:Type, _)
               => addToEnv(X, Base)
               ~> giveType(X, T')
          ...</k>
          <curr-scope> S:Scope </curr-scope>
          <curr-tu> TU:String </curr-tu>
          <tu-id> TU </tu-id>
          <local-statics>...
               kpair(X, S) |-> kpair(Base:SymBase, T':Type)
          ...</local-statics>
          requires isStaticType(T)
          [structural]
     rule declareInternalVariable(X:CId, _, initValue(_, T:Type, .K))
          => declareOnly(X, T)
          requires notBool isStaticType(T)
               andBool notBool isExternType(T)
               andBool notBool isFunctionType(T)
               andBool notBool isVariablyModifiedType(T)
          [structural]
     rule declareInternalVariable(X:CId, _, initValue(_, T:Type, Init:K))
          => declareAndDefine(X, T, Init)
          requires notBool isStaticType(T)
               andBool notBool isExternType(T)
               andBool notBool isFunctionType(T)
               andBool Init =/=K .K
               andBool notBool isVariablyModifiedType(T)
          [structural]
     rule declareInternalVariable(_, _, (initValue(X:CId, T:Type, Init:K)
               => stabilizeInitType(initValue(X, T, Init))))
          requires isVariablyModifiedType(T)
          [structural]

     syntax KItem ::= stabilizeInitType(K)
     rule (.K => stabilizeVLA(T)) ~> stabilizeInitType(initValue(_, T:Type, _))
          [structural]
     rule T:Type ~> stabilizeInitType(initValue(X:CId, _, K:K))
          => initValue(X, T, K)
          [structural]

     syntax KItem ::= declareOnly(CId, Type)
     rule <k> declareOnly(X:CId, T:Type)
               => defineAndInit(X, T, .K, !I:Int @ D)
          ...</k>
          <duration> D:Duration </duration>
          <local-vars> Vars:List (.List => ListItem(X)) </local-vars>
          requires isCompleteType(T)
               andBool notBool isRegisterType(T)
               andBool (notBool X in Vars)
          [structural]
     rule <k> declareOnly(X:CId, T:Type)
               => defineAndInit(X, T, .K, autoToRegister(!I:Int @ D))
          ...</k>
          <duration> D:Duration </duration>
          <local-vars> Vars:List (.List => ListItem(X)) </local-vars>
          requires isCompleteType(T)
               andBool isRegisterType(T)
               andBool (notBool X in Vars)
          [structural]
     // Same as above, but for the case where the variable has already been
     // declared. This is seen if we goto earlier in the same block.
     rule <k> declareOnly(X:CId, T:Type) => .K ...</k>
          <local-vars> Vars:List </local-vars>
          requires isCompleteType(T) andBool X in Vars
          [structural]

     syntax KItem ::= declareAndDefine(CId, Type, K)
     rule <k> declareAndDefine(X:CId, T:Type, Init:K)
               => defineAndInit(X, T, Init, !I:Int @ D)
          ...</k>
          <duration> D:Duration </duration>
          <local-vars> Vars:List (.List => ListItem(X)) </local-vars>
          requires notBool X in Vars
               andBool notBool isRegisterType(T)
          [structural]
     rule <k> declareAndDefine(X:CId, T:Type, Init:K)
               => defineAndInit(X, T, Init, autoToRegister(!I:Int @ D))
          ...</k>
          <duration> D:Duration </duration>
          <local-vars> Vars:List (.List => ListItem(X)) </local-vars>
          requires notBool X in Vars
               andBool isRegisterType(T)
          [structural]
     // This happens when we jump before a variable declaration with an
     // initialization in the same block.
     rule <k> declareAndDefine(X:CId, T:Type, Init:K)
               => giveType(X, T)
               ~> allowInit(Init)
               ~> sequencePoint
          ...</k>
          <local-vars> Vars:List </local-vars>
          requires X in Vars
          [structural]

     syntax KItem ::= defineAndInit(CId, Type, K, SymBase)
     rule <k> defineAndInit(X:CId, T:Type, K:K, Base:SymBase)
               => allocObject(Base, T)
               ~> addToEnv(X, Base)
               ~> giveType(X, T)
               ~> allowInit(K)
               ~> sequencePoint
          ...</k>
          <local-addresses>... .Set => SetItem(Base) ...</local-addresses>
          <should-init> true </should-init>
          [structural]
     rule <k> defineAndInit(X:CId, T:Type, _, Base:SymBase)
               => allocObject(Base, T)
               ~> addToEnv(X, Base)
               ~> giveType(X, T)
          ...</k>
          <local-addresses>... .Set => SetItem(Base) ...</local-addresses>
          <should-init> false </should-init>
          [structural]
     rule <k> defineAndInit(X:CId, T:Type, .K, Base:SymBase)
               => allocObject(Base, T)
               ~> addToEnv(X, Base)
               ~> giveType(X, T)
          ...</k>
          <local-addresses>... .Set => SetItem(Base) ...</local-addresses>
          [structural]

     syntax KItem ::= addLocalTag(CId, FieldInfo)
     rule <k> addLocalTag(X:CId, Info:FieldInfo) => .K ...</k>
          <structs> Structs:Map => Structs[local(X, Tu, BlockNum) <- Info] </structs>
          <curr-tu> Tu:String </curr-tu>
          <curr-scope> blockScope(_, BlockNum:Int) </curr-scope>
          [structural]

endmodule

