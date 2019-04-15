module CPP-TRANSLATION-TYPING-DEPENDENT
     imports CPP-TYPING-SYNTAX
     imports CPP-CLASS-BASIC-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION

     syntax Bool ::= #isDependentInScope(CPPDType, K) [function]

     // TODO(dwightguth): class member stuff
     rule isDependentInScope(T::CPPType) => #isDependentInScope(T, #configuration)

     rule areDependentInScope(T::TemplateArgs) => #areDependentInScope(T, #configuration)

     rule areDependentInScope(T::CPPTypes) => #areDependentInScope(T, #configuration)

     rule #isDependentInScope(T:CPPDType, _) => false

     rule #isDependentInScope(t(_, _, classType(_ :: Class(_, _, L::TemplateArgs))), Config:K) => #areDependentInScope(L, Config)

     rule #isDependentInScope(t(_, _, functionType(... returnType: T::CPPType, paramTypes: L::CPPTypes)), Config:K) => #isDependentInScope(T, Config) orBool #areDependentInScope(L, Config)

     rule #isDependentInScope(t(_, _, pointerType(T::CPPType)), Config:K) => #isDependentInScope(T, Config)

     rule #isDependentInScope(t(_, _, lvRefType(T::CPPType)), Config:K) => #isDependentInScope(T, Config)

     rule #isDependentInScope(t(_, _, rvRefType(T::CPPType)), Config:K) => #isDependentInScope(T, Config)

     rule #isDependentInScope(t(_, _, dependentType(Arg::String, I::Int)), <generatedTop>... <template-arguments> Args::Map </template-arguments> ...</generatedTop>) => notBool dependentType(Arg, I) in_keys(Args)

     rule #isDependentInScope(t(_, _, T:CPPSimpleAutoType), <generatedTop>... <template-arguments> Args::Map </template-arguments> ...</generatedTop>) => notBool T in_keys(Args)

     syntax Bool ::= #areDependentInScope(TemplateArgs, K) [function]

     syntax Bool ::= #areDependentInScope(CPPTypes, K) [function]

     rule #areDependentInScope(T:CPPType, L::TemplateArgs, Config:K) => #isDependentInScope(T, Config) orBool #areDependentInScope(L, Config)

     rule #areDependentInScope(T:CPPDType, L::CPPTypes, Config:K) => #isDependentInScope(T, Config) orBool #areDependentInScope(L, Config)

     rule #areDependentInScope(.TemplateArgs, _) => false

     rule #areDependentInScope(.CPPTypes, _) => false

     rule isAuto(T:CPPDType) => false

     rule isAuto(t(_, _, classType(_ :: Class(_, _, L::TemplateArgs)))) => areAuto(L)

     rule isAuto(t(_, _, functionType(... returnType: T::CPPType, paramTypes: L::CPPTypes))) => isAuto(T) orBool areAuto(L)

     rule isAuto(t(_, _, pointerType(T::CPPType))) => isAuto(T)

     rule isAuto(t(_, _, lvRefType(T::CPPType))) => isAuto(T)

     rule isAuto(t(_, _, rvRefType(T::CPPType))) => isAuto(T)

     rule isAuto(t(_, _, auto)) => true

     rule isAuto(t(_, _, dependentType(...))) => false

     syntax Bool ::= areAuto(CPPTypes) [function]

     syntax Bool ::= areAuto(TemplateArgs) [function]

     rule areAuto(T::CPPType, Ts::TemplateArgs) => isAuto(T) orBool areAuto(Ts)

     rule areAuto(T::CPPType, Ts::CPPTypes) => isAuto(T) orBool areAuto(Ts)

     rule areAuto(.TemplateArgs) => false

     rule areAuto(.CPPTypes) => false

endmodule
