module CPP-ENV-SYNTAX
     imports BASIC-K
     imports BOOL-SYNTAX
     imports COMPAT-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SYMLOC-SORTS
     imports CPP-TYPING-SORTS

     // identifier, type, location, is using declaration
     syntax KItem ::= addToEnv(QualId, CPPType, SymBase, Bool)
                    | scope(Scope, K)
                    | setScope(Scope)
                    | noEval(K)
                    | "recover"
     syntax KItem ::= "pushLocals" | "popLocals"
     syntax KItem ::= updateDefaultArguments(QualId, CPPType, DefaultArguments) [strict(3)]
     
     syntax DefaultArguments ::= defArgs(vals: StrictList, types: StrictList, cats: StrictList) [strict(1)]
     syntax DefaultArguments ::= DefaultArgumentsResult
     syntax DefaultArgumentsResult ::= defArgs(vals: StrictListResult, types: StrictListResult, cats: StrictListResult)
     syntax KResult ::= DefaultArgumentsResult

     syntax List ::= getDefaultArgsVals(DefaultArgumentsResult) [function]
     syntax List ::= getDefaultArgsTypes(DefaultArgumentsResult) [function]
     syntax List ::= getDefaultArgsCats(DefaultArgumentsResult) [function]

endmodule

module CPP-ENV
    imports CPP-ENV-SYNTAX
    imports C-CONFIGURATION
    imports BOOL
    imports K-EQUAL
    imports COMPAT-SYNTAX
    imports CPP-ABSTRACT-SYNTAX
    imports CPP-DYNAMIC-SYNTAX
    imports CPP-SYMLOC-SYNTAX
    imports CPP-TYPING-SYNTAX

    rule updateDefaultArguments(_, T::CPPType, _) => .K 
         requires notBool isCPPFunctionType(T)

    rule <k> addToEnv(N:Namespace :: X::CId, T:CPPFunctionType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <curr-tu> Tu::String </curr-tu>
         <tu-id> Tu </tu-id>
         <ns-id> N </ns-id>
         <nenv> NE::Map => NE[X <- updateFnEnv(NE, X, T, Base, IsUsing)] </nenv>
         requires N =/=K NoNamespace()
    
    rule <k> updateDefaultArguments(N:Namespace :: X::CId, T:CPPFunctionType, A1:DefaultArgumentsResult) => .K ...</k>
         <curr-tu> Tu::String </curr-tu>
         <tu-id> Tu </tu-id>
         <ns-id> N </ns-id>
         <nenv>... X |-> (_ T |-> envEntry(... defaultArgs: A2::DefaultArgumentsResult => #updateDefaultArgs(A1, A2))) ...</nenv>
         requires N =/=K NoNamespace()

    rule <k> addToEnv(N:Namespace :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <curr-tu> Tu::String </curr-tu>
         <tu-id> Tu </tu-id>
         <ns-id> N </ns-id>
         <nenv> NE::Map => NE[X <- T |-> envEntry(Base, IsUsing, NoDefArgs())] </nenv>
         requires N =/=K NoNamespace() andBool notBool isCPPFunctionType(T)

    rule <k> addToEnv(NoNamespace() :: X::CId, T:CPPFunctionType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <env> NE::Map => NE[X <- updateFnEnv(NE, X, T, Base, IsUsing)] </env>

    rule <k> updateDefaultArguments(NoNamespace() :: X::CId, T:CPPFunctionType, A1:DefaultArgumentsResult) => .K ...</k>
         <env>... X |-> (_ T |-> envEntry(... defaultArgs: A2::DefaultArgumentsResult => #updateDefaultArgs(A1, A2))) ...</env>

    rule <k> addToEnv(NoNamespace() :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <env> NE::Map => NE[X <- T |-> envEntry(Base, IsUsing, NoDefArgs())] </env>
         requires notBool isCPPFunctionType(T)

    rule <k> addToEnv(C:Class :: X::CId, T:CPPFunctionType, Base::SymBase, IsUsing::Bool) 
             => .K
         ...</k>
         <class-id> C </class-id>
         <cenv> CE::Map => CE[X <- updateFnEnv(CE, X, T, Base, IsUsing)] </cenv>

     rule <k> updateDefaultArguments(C:Class :: X::CId, T:CPPFunctionType, A1:DefaultArgumentsResult) => .K ...</k>
          <class-id> C </class-id>
          <cenv>... X |-> (_ T |-> envEntry(... defaultArgs: A2::DefaultArgumentsResult => #updateDefaultArgs(A1, A2))) ...</cenv>

    rule <k> addToEnv(C:Class :: X::CId, T::CPPType, Base::SymBase, IsUsing::Bool)
             => .K
         ...</k>
         <class-id> C </class-id>
         <cenv> CE::Map => CE[X <- T |-> envEntry(Base, IsUsing, NoDefArgs())] </cenv>
         requires notBool isCPPFunctionType(T)

     rule getDefaultArgsVals(defArgs(... vals: krlist(Args::List))) => Args
     rule getDefaultArgsTypes(defArgs(... types: krlist(Types::List))) => Types
     rule getDefaultArgsCats(defArgs(... cats: krlist(Cats::List))) => Cats

     syntax Map ::= updateFnEnv(Map, CId, CPPFunctionType, SymBase, Bool) [function]
     rule updateFnEnv(Env::Map, X::CId, T::CPPFunctionType, Base::SymBase, IsUsing::Bool) => T |-> envEntry(Base, IsUsing, emptyDefaultArguments(T))
          requires notBool X in_keys(Env)
     rule updateFnEnv(_ X |-> XEnv::Map, X::CId, T::CPPFunctionType, Base::SymBase, IsUsing::Bool)
          => #updateFnEnv(XEnv, T, Base, IsUsing)

     syntax Map ::= #updateFnEnv(Map, CPPFunctionType, SymBase, Bool) [function]
     rule #updateFnEnv(XEnv::Map T |-> Entry:EnvEntry, T::CPPFunctionType, Base::SymBase, IsUsing::Bool)
          => XEnv T |-> #fun(envEntry(... base: _ => Base, using: _ => IsUsing))(Entry)
     rule #updateFnEnv(XEnv::Map, T::CPPFunctionType, Base::SymBase, IsUsing::Bool) => XEnv T |-> envEntry(Base, IsUsing, emptyDefaultArguments(T)) [owise]

     syntax DefaultArgumentsResult ::= #updateDefaultArgs(newArgs: DefaultArgumentsResult, oldArgs: DefaultArgumentsResult) [function]
     rule #updateDefaultArgs(NewArgs::DefaultArgumentsResult, OldArgs::DefaultArgumentsResult)
          => #updateDefaultArgs(NewArgs, OldArgs, defArgs(krlist(.List), krlist(.List), krlist(.List)))

     syntax DefaultArgumentsResult ::= #updateDefaultArgs(newArgs: DefaultArgumentsResult, oldArgs: DefaultArgumentsResult, resultArgs: DefaultArgumentsResult) [function, klabel(updateDefaultArgsHelper)]
    // The next rule compensates for the clang policy to aggregate existing default args from previous declarations
    // Hence, we'll trust clang to check that the user does not redefine an old def. arg.
     rule #updateDefaultArgs(
            defArgs(krlist((ListItem(_) => .List) _),
                    krlist((ListItem(_) => .List) _),
                    krlist((ListItem(_) => .List) _)),
            defArgs(krlist((ListItem(I::Init) => .List) _),
                    krlist((ListItem(C::ValueCategory) => .List) _),
                    krlist((ListItem(T::CPPDType) => .List) _)),
            defArgs(krlist(_::List (.List => ListItem(I::Init))),
                    krlist(_::List (.List => ListItem(C::ValueCategory))),
                    krlist(_::List (.List => ListItem(T::CPPDType)))))
          requires I =/=K NoArg()

     rule #updateDefaultArgs(
            defArgs(krlist((ListItem(I::Init) => .List) _),
                    krlist((ListItem(C::ValueCategory) => .List) _),
                    krlist((ListItem(T::CPPDType) => .List) _)),
            defArgs(krlist((ListItem(NoArg()) => .List) _),
                    krlist((ListItem(_) => .List) _),
                    krlist((ListItem(_) => .List) _)),
            defArgs(krlist(_::List (.List => ListItem(I::Init))),
                    krlist(_::List (.List => ListItem(C::ValueCategory))),
                    krlist(_::List (.List => ListItem(T::CPPDType)))))
     rule #updateDefaultArgs(
            defArgs(krlist(.List), krlist(.List), krlist(.List)),
            defArgs(krlist(.List), krlist(.List), krlist(.List)),
            DA::DefaultArgumentsResult) => DA


     rule <k> scope(Scope::Scope, K:K)
              => pushLocals ~> K ~> popLocals ~> setScope(OldScope)
          ...</k>
          <curr-scope> OldScope::Scope => Scope </curr-scope>

     rule <k> setScope(Scope::Scope) => .K ...</k>
          <curr-scope> _ => Scope </curr-scope>

     rule <k> pushLocals => .K ...</k>
          <block-control> C::Bag </block-control>
          <block-stack>
               .List => ListItem(<block-control> C </block-control>)
          ...</block-stack>

     rule <k> popLocals => .K ...</k>
          (_:BlockControlCell => L)
          <block-stack>
               ListItem(L:BlockControlCell) => .List
          ...</block-stack>

     rule <k> noEval(K:K)
              => setEval(noEval) ~> pushLocals ~> K ~> popLocals ~> setEval(OldEval)
          ...</k>
          <curr-eval-context> OldEval::EvalContext </curr-eval-context>

     syntax KItem ::= setEval(EvalContext)
     rule <k> setEval(Eval::EvalContext) => .K ...</k>
          <curr-eval-context> _ => Eval </curr-eval-context>

     rule recover ~> (K:KItem => .K)
          requires K =/=K popLocals
     rule (recover => .K) ~> popLocals

endmodule
