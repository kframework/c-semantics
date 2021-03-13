module CPP-TRANSLATION-DECL-LINKAGE
     imports C-CONFIGURATION
     imports STRING
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-ERROR-SYNTAX

     syntax KItem ::= setLinkage(LanguageLinkage, Bool)

     syntax LanguageLinkage ::= "stuck"

     rule <k> LinkageSpec(Linkage:String, HasBraces:Bool, Decls:List)

              // error checking handled by parser
              => setLinkage(#if Linkage ==String "C" #then CLinkage #else #if Linkage ==String "C++" #then CPPLinkage #else stuck #fi #fi,
                            #if notBool HasBraces #then true #else OldExtern #fi)
              ~> listToK(Decls)
              ~> setLinkage(OldLinkage, OldExtern)
          ...</k>
          <curr-tr-scope> _:NamespaceScope </curr-tr-scope>
          <curr-lang-linkage> OldLinkage:LanguageLinkage </curr-lang-linkage>
          <curr-extern> OldExtern::Bool </curr-extern>

     rule <k> setLinkage(Linkage:LanguageLinkage, OldExtern::Bool) => .K ...</k>
          <curr-lang-linkage> _ => Linkage </curr-lang-linkage>
          <curr-extern> _ => OldExtern </curr-extern>

endmodule
