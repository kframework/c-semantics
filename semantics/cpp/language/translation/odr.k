module CPP-TRANSLATION-ODR-SYNTAX
     imports BASIC-K
     imports SYMLOC-SORTS
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= "Odr.newUse" "(" SymBase ")"
     syntax KItem ::= "Odr.newDef" "(" QualId "," CPPType "," SymBase ")"
     syntax KItem ::= "Odr.newDecl" "(" CId "," QualId "," CPPType "," SymBase ")"
     syntax KItem ::= "Odr.doWhenUsed" "(" SymBase "," K  ")"
     syntax KItem ::= generateOdrUsedFunctions()

endmodule

module CPP-TRANSLATION-ODR
     imports CPP-TRANSLATION-ODR-SYNTAX
     imports K-EQUAL
     imports SET
     imports MAP
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

     rule <k> Odr.doWhenUsed(Base::SymBase, K:KItem) => .K ...</k>
          <odr-uses> _Uses::Set </odr-uses>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <when-odr-used>... .Map => Base |-> K </when-odr-used>

     rule <k> generateOdrUsedFunctions() => .K ...</k>
          <odr-uses> Uses::Set </odr-uses>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <when-odr-used> OU::Map => .Map </when-odr-used>
          requires intersectSet(keys(OU), Uses) ==K .Set

     rule <k> (.K => generateOdrUsedFunction({choice(intersectSet(keys(OU), Uses)::Set)}:>SymBase))
          ~> generateOdrUsedFunctions() ...</k>
          <odr-uses> Uses::Set </odr-uses>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <when-odr-used> OU::Map </when-odr-used>
          requires intersectSet(keys(OU), Uses) =/=K .Set

     syntax KItem ::= generateOdrUsedFunction(SymBase)

     rule <k> generateOdrUsedFunction(Base::SymBase) => OU[Base] ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <when-odr-used> OU::Map => OU[Base <- undef] </when-odr-used>

endmodule
