module CPP-EXPR-MEMBERS-SYNTAX
     imports INT
     imports CPP-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     syntax Expr ::= fieldExp(Expr, Name, CPPType, Int) [strict(1)]
endmodule

module CPP-EXPR-MEMBERS
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports SETTINGS-SYNTAX
     imports CPP-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> This() => Obj ...</k>
          <this> Obj::Expr </this>

     context HOLE:Expr . _ _

     rule V:Val . no-template (Name(_:Class, _) #as N::Name)
       => lookupFieldCPP(V, N, 0)

     syntax KItem ::= lookupFieldCPP(Val, Name, Int)
     //TODO(traiansf): Check access permissions
     rule <k> lookupFieldCPP(V::Val, Name(FC::Class, F::CId) #as N::Name, PrevOffset::Int)
           => fieldExp(V, N, addQuals(getQuals(type(V)), T), Offset +Int PrevOffset)
          ...</k>
          <class-id> FC </class-id>
          <cenv>... F |-> (T::CPPType |-> classOffset(Offset::Int)) ...</cenv>

     rule <k> lookupFieldCPP(V::Val, Name(FC::Class => C, F::CId), PrevOffset::Int => PrevOffset +Int Offset) ...</k>
          <class-id> FC </class-id>
          <cenv>... F |-> (_ |-> envEntry(... base: memberBase(unnamedObject(C::Class), _, _))) unnamedObject(C) |-> (_ |-> classOffset(Offset::Int)) ...</cenv>

     rule fieldExp(lv(Loc:SymLoc, _, _), _, T::CPPType, Offset::Int)
          => lv(Loc +bytes Offset /Int cfg:bitsPerByte, noTrace, T)
          requires notBool isCPPBitfieldType(T)

     rule E::Expr -> T::TemplateKeyword N::Name => (* E) . T N [anywhere]
endmodule
