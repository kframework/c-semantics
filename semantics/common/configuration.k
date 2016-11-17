module COMMON-CONFIGURATION
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports MAP
  imports SET
  imports STRING-SYNTAX
  imports COMMON-SYNTAX

  configuration
  <global>
     <mem> .Map </mem>
     <references> .Map </references>
     <functions color="lightgray"> .Map </functions>

     <main-tu color="lightgray"> .Set </main-tu>

     <global-state>
          // CId |-> Types
          <external-types> .Map </external-types>
          // CId |-> Loc
          <external-defs> .Map </external-defs>
          // QualId |-> (Type |-> Loc)
          <odr-defs> .Map </odr-defs>
          // dummy link base |-> real base
          <linkings> .Map </linkings>
     </global-state>

     <linking-state multiplicity="?" initial="">
          // CId |-> Set(TUs)
          <external-decls> .Map </external-decls>
          // CIds |-> CabsLoc
          <external-uses> .Map </external-uses>
          // CId |-> CabsLoc
          <external-defs-loc> .Map </external-defs-loc>
          // SymBase |-> Set(ktriple(TU, QualId, Type))
          <odr-decls> .Map </odr-decls>
          // Set(SymBase)
          <odr-uses> .Set </odr-uses>
     </linking-state>

     <tags color="lightgray"> .Map </tags>

     <dynamic-init> .K </dynamic-init>

     <translation-units>
          <tu multiplicity="*" type="Map">
               <tu-id> "" </tu-id>
               <genv color="lightgray"> .Map </genv>
               <gtypes color="lightgray"> .Map </gtypes>

               // kpair(CId, Scope) |-> kpair(SymBase, Type)
               <local-statics> .Map </local-statics>

               <tu-linking-state multiplicity="?" initial="">
                    <externals> .Map </externals>
                    <internals> .Map </internals>
                    <next-link-loc> .K </next-link-loc>
                    <next-static-loc> .K </next-static-loc>
                    <uses> SetItem(Identifier("main")) </uses>
                    <genums> .Map </genums>
                    // QualId |-> (CPPType |-> TemplateInfo)
                    <templates> .Map </templates>
               </tu-linking-state>

               <next-unnamed color="black"> 0 </next-unnamed>

               <goto-map color="lightgray"> .Map </goto-map>

               // TODO(chathhorn): remove.
               <incomplete-tags> .Set </incomplete-tags>

               // C++ stuff
               <namespaces>
                    <ns multiplicity="*" type="Map">
                         <ns-id> GlobalNamespace() </ns-id>
                         // CId |-> (CPPType |-> SymBase)
                         <nenv> .Map </nenv>
                         // CId |-> (Tag |-> CPPType)
                         <ntypes> .Map </ntypes>
                         // CId |-> Namespace
                         <nested-namespaces> .Map </nested-namespaces>
                         <is-inline> false </is-inline>
                         <using-namespaces> .Set </using-namespaces>
                         <inline-namespaces> .Set </inline-namespaces>
                    </ns>
               </namespaces>

               <classes color="lightgray">
                    <class multiplicity="*" type="Map">
                         <class-id> .K </class-id>
                         <class-type> .K </class-type>
                         <is-aggregate> true </is-aggregate>
                         <base-classes> .List </base-classes>
                         <cenv> .Map </cenv>
                         <initializers> .Map </initializers>
                         <ctypes> .Map </ctypes>
                         <non-static-data-members> .List </non-static-data-members>
                         <access> .Map </access>
                         <max-offset> 0 </max-offset>
                         <max-align> 1 </max-align>
                         <access-specifier> .K </access-specifier>
                    </class>
               </classes>

               <cpp-enums>
                    <cppenum multiplicity="*" type="Map">
                         <enum-id> .K </enum-id>
                         <enum-ut> .K </enum-ut>
                         <scoped> false </scoped>
                         <enumerators> .List </enumerators>
                    </cppenum>
               </cpp-enums>

          </tu>
     </translation-units>
   </global>

endmodule
