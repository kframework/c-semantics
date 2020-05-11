module CPP-EXECUTION-EXPR-MEMBERS
     imports C-CONFIGURATION
     imports CPP-BINDING-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> This() => Obj ...</k>
          <this> Obj::Expr </this>
          requires Execution()

     rule contrivedObject(_) => noObject()
          requires Execution()

     rule <k> evalBraceOrEqualInitializer(C::Class, lv(Loc::SymLoc, Tr::Trace, T::CPPType) #as Base::LVal, E::Expr) => setThis(prv(Loc, Tr, type(pointerType(type(classType(C)))))) ~> E ~> returnFromBraceOrEqualInitializer(Base, OldScope) ~> setThis(OldThis) ...</k>
          <curr-scope> OldScope::Scope => classScope(C, true) </curr-scope>
          <this> OldThis::K </this>
          requires Execution()

     rule <k> V:Val ~> (returnFromBraceOrEqualInitializer(_, Scope::Scope) ~> setThis(OldThis::K) => .K) ...</k>
          <curr-scope> _ => Scope </curr-scope>
          <this> _ => OldThis </this>
          requires Execution() andBool notBool (isLExpr(V) orBool isPRExpr(V))
endmodule
