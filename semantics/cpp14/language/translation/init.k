module CPP-TRANSLATION-INIT-SYNTAX
     imports COMMON-SORTS

     syntax KItem ::= makeNs(Namespace)
endmodule

module CPP-TRANSLATION-INIT
     imports CPP-TRANSLATION-INIT-SYNTAX
     imports STRING
     imports C-LINKING-INIT-SYNTAX
     imports C-LINKING-RESOLUTION-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-TYPING-SYNTAX

     imports C-CONFIGURATION

     rule <k> TranslationUnit(TU:String, Decls:List)
               => makeTu(TU +String newUUID)
               ~> makeNs(GlobalNamespace())
               ~> listToK(Decls)
               ~> removeUnusedIdentifiers
          ...</k>
          // don't delete this... we want to make sure the fresh counter starts
          // at 1 for each TU because unlike C, C++ doesn't give us unique block
          // numbers directly from the parser, so we are using the fresh counter to
          // assign block numbers. But the fresh counter starts at 0 and block 0
          // is the privileged "haven't entered the outer block of the function yet"
          // block.
          requires !Fresh:Int >=Int 0 

     rule <k> makeNs(N::Namespace) => .K ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <namespaces>...
               (.Bag => <ns>...
                             <ns-id> N </ns-id>
                        ...</ns>)
          ...</namespaces>

     rule isCLinkage(t(_, _, functionType(_, _, CLinkage))) => true
     rule isCLinkage(_) => false [owise]
endmodule
