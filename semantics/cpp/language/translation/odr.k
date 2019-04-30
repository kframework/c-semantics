module CPP-TRANSLATION-ODR-SYNTAX
     imports BASIC-K
     imports SYMLOC-SORTS
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= "Odr.newUse" "(" SymBase ")"

     syntax KItem ::= "Odr.newDef" "(" QualId "," CPPType "," SymBase ")"

     syntax KItem ::= "Odr.newDecl" "(" CId "," QualId "," CPPType "," SymBase ")"

endmodule

module CPP-TRANSLATION-ODR
     imports CPP-TRANSLATION-ODR-SYNTAX
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule <k> Odr.newUse(Base::SymBase) => .K ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>

     rule <k> Odr.newDef(Q::QualId, T::CPPType, Base::SymBase) => .K ...</k>
          <odr-defs> Defs::Map => Defs[Q, T <- Base] </odr-defs>

     rule <k> Odr.newDecl(CName::CId, Q::QualId, T::CPPType, Base::SymBase) => .K ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <curr-lang-linkage> LangLinkage::LanguageLinkage </curr-lang-linkage>
          <odr-decls> Decls::Map => Decls[Base += odrDecl(Tu, Q, CName, LangLinkage, T)] </odr-decls>

endmodule
