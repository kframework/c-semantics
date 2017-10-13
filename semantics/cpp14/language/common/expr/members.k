module CPP-EXPR-MEMBERS-SYNTAX
     imports INT
     imports CPP-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     syntax Expr ::= fieldExp(Expr, CPPType, Int) [strict(1)]
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
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> This() => Obj ...</k>
          <this> Obj::Expr </this>

     context HOLE:Expr . _ _

     rule V:Val . no-template (Name(_:Class, _) #as N::Name)
       => lookupFieldCPP(V, type(V), N, 0)

     syntax KItem ::= lookupFieldCPP(Val, CPPType, Name, Int)
     //TODO(traiansf): Check access permissions
     rule <k> lookupFieldCPP(V::Val, TC::CPPType, Name(FC::Class, F::CId), PrevOffset::Int)
           => fieldExp(V, addQuals(getQuals(type(V)), T), Offset +Int PrevOffset)
          ...</k>
          <class-id> FC </class-id>
          <cenv>... F |-> (T::CPPType |-> classOffset(Offset::Int)) ...</cenv>
          requires type(simpleType(TC)) ==Type type(classType(FC))

     rule <k> lookupFieldCPP(V::Val, t(... st: classType(DC::Class => BC)), Name(BC::Class, _), PrevOffset::Int => PrevOffset +Int Offset)
          ...</k>
          <class-id> DC </class-id>
          <cenv>... baseClass(BC)  |-> (_ |-> classOffset(Offset::Int)) ...</cenv>
          requires isBaseClassOf(BC, DC)

     rule <k> lookupFieldCPP(V::Val, _, Name(FC::Class => C, F::CId), PrevOffset::Int => PrevOffset +Int Offset) ...</k>
          <class-id> FC </class-id>
          <cenv>... F |-> (_::CPPType |-> envEntry(... base: memberBase(unnamedObject(C::Class), _, _))) unnamedObject(C) |-> (_::CPPType |-> classOffset(Offset::Int)) ...</cenv>

     rule fieldExp(lv(Loc:SymLoc, _, _), T::CPPType, Offset::Int)
          => lv(Loc +bytes Offset /Int cfg:bitsPerByte, noTrace, T)
          requires notBool isCPPBitfieldType(T)

     rule E::Expr -> T::TemplateKeyword N::Name => (* E) . T N [anywhere]
endmodule
