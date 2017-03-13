module CPP-EXECUTION-EXPR-MEMBERS 
     imports C-CONFIGURATION
     imports CPP-BINDING-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> This() => Obj ...</k>
          <this> Obj::Expr </this>

     rule contrivedObject(_) => noObject()

     rule <k> evalBraceOrEqualInitializer(C::Class, lv(Loc::SymLoc, Tr::Trace, T::CPPType) #as Base::LVal, E::Expr) => setThis(prv(Loc, Tr, type(pointerType(type(classType(C)))))) ~> E ~> returnFromBraceOrEqualInitializer(Base, OldScope) ~> setThis(OldThis) ...</k>
          <curr-scope> OldScope::Scope => classScope(C) </curr-scope>
          <this> OldThis::PRVal </this>

     rule <k> V:Val ~> (returnFromBraceOrEqualInitializer(_, Scope::Scope) ~> setThis(OldThis::PRVal) => .K) ...</k>
          <curr-scope> _ => Scope </curr-scope>
          <this> _ => OldThis </this>
          requires notBool (isLExpr(V) orBool isPRExpr(V))
endmodule
