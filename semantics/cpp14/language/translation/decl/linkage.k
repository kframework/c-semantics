module CPP-DECL-LINKAGE
     imports CPP-ERROR-SYNTAX
     imports C-CONFIGURATION

     syntax KItem ::= setLinkage(LanguageLinkage)

     rule <k> LinkageSpec(Linkage:String, Decls:List) 
              // error checking handled by parser
              => setLinkage(#if Linkage ==String "C" #then CLinkage #else #if Linkage ==String "C++" #then CPPLinkage #else .K #fi #fi:>LanguageLinkage) 
              ~> listToK(Decls)
              ~> setLinkage(OldLinkage)
          ...</k>
          <curr-scope> N:NamespaceScope </curr-scope>
          <curr-lang-linkage> OldLinkage:LanguageLinkage </curr-lang-linkage>

     rule <k> setLinkage(Linkage:LanguageLinkage) => .K ...</k>
          <curr-lang-linkage> _ => Linkage </curr-lang-linkage>

endmodule
