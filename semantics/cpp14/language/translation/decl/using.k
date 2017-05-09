module CPP-DECL-USING
     imports C-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SORTS

     context UsingDecl(_, HOLE:NNS, _) [result(NNSVal)]

     // using an object
     rule <k> UsingDecl(false, UsingN::Namespace, X::CId) => .K ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns>...
            <ns-id> N </ns-id>
            <nenv> NE::Map => NE [X <+ makeUsing(UsingM)] </nenv>
          ...</ns>
          <ns>...
            <ns-id> UsingN </ns-id>
            <nenv>... X |-> UsingM::Map ...</nenv>
          ...</ns>

     // using a type
     rule <k> UsingDecl(false, UsingN::Namespace, X::CId) => .K ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns>...
            <ns-id> N </ns-id>
            <ntypes> NE::Map => NE [X, Tag <- UsingT] </ntypes>
          ...</ns>
          <ns>...
            <ns-id> UsingN </ns-id>
            <ntypes>... X |-> (Tag::ClassKey |-> UsingT::CPPType) ...</ntypes>
          ...</ns>


     syntax Map ::= makeUsing(Map) [function]

     rule makeUsing(T::CPPType |-> envEntry(Base::SymBase, _, Args::DefaultArgumentsResult) M::Map)
          => T |-> envEntry(Base, true, Args) makeUsing(M)
     rule makeUsing(.Map) => .Map

endmodule
