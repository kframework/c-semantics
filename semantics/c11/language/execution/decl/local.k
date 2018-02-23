module C-DECL-LOCAL
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports K-EQUAL
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

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
          requires (isExternType(T) orBool isFunctionType(T))
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
     rule <k> declareInternalVariable(X:CId, _, initValue(_, T::Type, Init:K))
               => declareAndDefine(X, T, Init)
          ...</k>
          <env> Env::Map </env>
          requires notBool isStaticType(T)
               andBool notBool isExternType(T)
               andBool notBool isFunctionType(T)
               andBool notBool isVariablyModifiedType(T)
               andBool notBool (isCompoundLiteralId(X) andBool X in_keys(Env))
          [structural]
     // Compound literal encountered again after goto.
     rule <k> declareInternalVariable(X:CId, _, initValue(_, T::Type, Init:K))
               => Init
               ~> sequencePoint
          ...</k>
          <env> Env::Map </env>
          requires notBool isStaticType(T)
               andBool notBool isExternType(T)
               andBool notBool isFunctionType(T)
               andBool notBool isVariablyModifiedType(T)
               andBool isCompoundLiteralId(X) andBool X in_keys(Env)
          [structural]
     rule declareInternalVariable(_, _, (initValue(X::CId, T::Type, Init:K)
               => stabilizeInitType(initValue(X, T, Init))))
          requires isVariablyModifiedType(T)
          [structural]

     syntax KItem ::= stabilizeInitType(K)
     rule (.K => stabilizeVLA(T)) ~> stabilizeInitType(initValue(_, T::Type, _))
          [structural]
     rule <k> T:Type ~> stabilizeInitType(initValue(X::CId, _, K:K))
          => checkStackDepth ~> initValue(X, T, K) ...</k>
          <stack-depth> I::Int => I +Int cfg:stackSize(.List, ListItem(T)) </stack-depth>
          [structural]

     syntax KItem ::= declareAndDefine(CId, Type, K)
     rule <k> declareAndDefine(X:CId, T:Type, Init:K)
               => defineAndInit(X, T, Init, linc(T, D))
          ...</k>
          <duration> D:Duration </duration>
          <local-vars>... .Set => SetItem(X) </local-vars>
          requires notBool isRegisterType(T)
          [structural]
     rule <k> declareAndDefine(X:CId, T:Type, Init:K)
               => defineAndInit(X, T, Init, autoToRegister(linc(T, D)))
          ...</k>
          <duration> D:Duration </duration>
          <local-vars>... .Set => SetItem(X) </local-vars>
          requires isRegisterType(T)
          [structural]

     syntax KItem ::= defineAndInit(CId, Type, K, SymBase)
     rule <k> defineAndInit(X:CId, T:Type, Init:K, Base:SymBase)
               => allocObject(Base, T)
               ~> addToEnv(X, Base)
               ~> giveType(X, T)
               ~> Init
               ~> sequencePoint
          ...</k>
          <local-addresses>... .Set => SetItem(Base) ...</local-addresses>
          <should-init> true </should-init>
          requires Init =/=K .K
          [structural]
     rule <k> defineAndInit(X:CId, T:Type, Init:K, Base:SymBase)
               => allocObject(Base, T)
               ~> addToEnv(X, Base)
               ~> giveType(X, T)
          ...</k>
          <local-addresses>... .Set => SetItem(Base) ...</local-addresses>
          <should-init> ShouldInit:Bool </should-init>
          requires Init ==K .K orBool notBool ShouldInit
          [structural]

endmodule

