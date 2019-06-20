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

     context HOLE:Expr . _ _

     rule V:Val . no-template (Name(_:Class, _) #as N::Name)
       => lookupFieldCPP(V, type(V), N, 0)


     syntax KItem ::= lookupFieldCPP(Val, CPPType, Name, Int)

     //TODO(traiansf): Check access permissions
     rule <k> lookupFieldCPP(V::Val, TC::CPPType, Name(FC::Class, F::CId), PrevOffset::Int)
           => fieldExp(V, addQuals(getQuals(type(V)), T), Offset +Int PrevOffset)
          ...</k>
          <class-id> FC </class-id>
          <cenv>... F |-> (T::CPPType |-> classOffset(_, Offset::Int)) ...</cenv>
          requires type(simpleType(TC)) ==Type type(classType(FC))

     rule lookupFieldCPP(_::Val, t(... st: classType(DC::Class => BC)), Name(BC::Class, _), PrevOffset::Int => PrevOffset +Int getBaseClassOffset(BC, DC))
          requires isProperBaseClassOf(BC, DC)

     rule <k> lookupFieldCPP(_::Val, t(... st: classType(FC::Class => C)), Name(FC::Class => C, F::CId), PrevOffset::Int => PrevOffset +Int Offset) ...</k>
          <class-id> FC </class-id>
          <cenv>... F |-> (_::CPPType |-> envEntry(... base: memberBase(unnamedObject(C::Class), _, _))) unnamedObject(C) |-> (_::CPPType |-> classOffset(_, Offset::Int)) ...</cenv>

     rule fieldExp(L::GLVal, T::CPPType, Offset::Int)
          => makeVal(cat(L), locOf(L) +bytes Offset /Int cfg:bitsPerByte, noTrace, T)
          requires isEvalVal(L) andBool notBool isCPPBitfieldType(T)

     rule E::Expr -> T::TemplateKeyword N::Name => (* E) . T N [anywhere]
endmodule
