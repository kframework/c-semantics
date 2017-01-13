module CPP-EXPR-MEMBERS
     imports BOOL
     imports INT
     imports C-CONFIGURATION
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYNTAX
     imports SETTINGS-SYNTAX
     imports SYMLOC-SYNTAX

     rule le(E::Expr, Trace::Trace, T::CPPType). TK::TemplateKeyword N::Name
          => le(E . TK N, Trace, T)

     context HOLE:Expr . _ _

     rule lv(Loc:SymLoc, _, T:CPPClassType) . no-template Name(NoNNS(), F:CId) => lookupFieldCPP(F, Loc, getQuals(T), getClassInfo(T))

     syntax KItem ::= lookupFieldCPP(CId, SymLoc, Quals, ClassInfo)
     rule <k> lookupFieldCPP(F::CId, Loc::SymLoc, Qs::Quals,
            <class>...
              <cenv>... F |-> (T::CPPType |-> O::Int) ...</cenv>
            ...</class>)
          => lv(Loc +bytes O /Int cfg:bitsPerByte, noTrace, addQuals(Qs, T))
          ...</k>
          requires notBool isCPPBitfieldType(T)
endmodule
