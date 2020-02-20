module COMMON-LINKING-DEPS-SYNTAX

     // forward declarations
     syntax String
     syntax Map
     syntax CId
     syntax CabsLoc

     syntax InternalOrExternal ::= internal(String) | external()
     syntax LinkdepNode ::= linkdepNode(CId, InternalOrExternal)
                          | linkdepNodeFromCId(CId) [function]

     syntax Map ::= updateLinkdep(Map, LinkdepNode, LinkdepNode, CabsLoc) [function]


     // TODO
     syntax Map ::= mergeLinkdep(Map, Map) [function]

endmodule

module COMMON-LINKING-DEPS
     imports COMMON-LINKING-DEPS-SYNTAX
     imports DOMAINS
     imports C-CONFIGURATION

     // The maps have the following form:
     // linkdepNode |-> (linkdepNode |-> CabsLoc)

     rule updateLinkdep(M::Map, From::LinkdepNode, To::LinkdepNode, Where::CabsLoc)
       => M [From <- ((M [ From ] orDefault .Map)[To <- Where])]


     rule mergeLinkdep(M1, .Map) => M1

     // generally, the keys of two maps will be independent,
     // since keys corresponds to function definition
     // and every function may be defined only once.
     // But for C++, we want a special not-a-function key corresponding
     // to situations where a symbol is used from outside a function,
     // e.g. from the global namespace.
     rule mergeLinkdep(M1, M2)
          => (From => mergeLinkdep(
               M1[From <- updateMap(M1[From] orDefault .Map, M2[From])],
               M2[From <- undef])
             )(choice(M2))

     // but what if the rule in global fires earlier than when externals/internals are filled?
     rule [[linkdepNodeFromCId(X) => linkdepNode(X, external())]]
          <externals>... X |-> _ ...</externals>
     rule [[linkdepNodeFromCId(X) => linkdepNode(X, internal(TU))]]
          <internals>... X |-> _ ...</internals>
          <curr-tu> TU::String </curr-tu>


endmodule
