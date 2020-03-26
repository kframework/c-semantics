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
     <goto-map color="lightgray"> .Map </goto-map>

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
          <function-tus> .Map </function-tus>
     </global-state>

     <linking-state multiplicity="?" initial="">
          // CId |-> Set(TUs)
          <external-decls> .Map </external-decls>
          // CId |-> CabsLoc
          <external-decls-loc> .Map </external-decls-loc>
          // CIds |-> CabsLoc
          <external-uses> .Map </external-uses>
          // linkdepNode |-> (linkdepNode |-> CabsLoc)
          <linking-deps> .Map </linking-deps>
          // CId |-> CabsLoc
          <external-defs-loc> .Map </external-defs-loc>
          // SymBase |-> Set(ktriple(TU, QualId, Type))
          <odr-decls> .Map </odr-decls>
          // Set(SymBase)
          <odr-uses> .Set </odr-uses>
     </linking-state>

     <tags color="lightgray"> .Map </tags>

     <unnamed-locs> .Map </unnamed-locs>

     <dynamic-init> .K </dynamic-init>

     <constexpr-symbase> .Set </constexpr-symbase>

     <translation-units>
          <tu multiplicity="*" type="Map">
               <tu-id> "" </tu-id>
               <genv color="lightgray"> .Map </genv>
               // reverse global environment
               <rgenv color="lightgray"> .Map </rgenv>
               <gtypes color="lightgray"> .Map </gtypes>

               // Set of blocks containing decls for restrict-qualified
               // pointers.
               <has-restrict> .Set </has-restrict>

               // kpair(CId, Scope) |-> kpair(SymBase, Type)
               <local-statics> .Map </local-statics>

               <tu-linking-state multiplicity="?" initial="">
                    <externals> .Map </externals>
                    <internals> .Map </internals>
                    <uses> .Set </uses>
                    <genums> .Map </genums>
                    // QualId |-> (CPPType |-> TemplateInfo)
                    <templates> .Map </templates>
               </tu-linking-state>

               <next-unnamed color="black"> 0 </next-unnamed>

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
                         // CId |-> Enum
                         <nenums> .Map </nenums>
                         <is-inline> false </is-inline>
                         <nusing-namespaces> .Set </nusing-namespaces>
                         <inline-namespaces> .Set </inline-namespaces>
                    </ns>
               </namespaces>

               <classes color="lightgray">
                    <class multiplicity="*" type="Map">
                         <class-id> .K </class-id>
                         <class-type> .K </class-type>
                         <is-aggregate> true </is-aggregate>
                         <base-classes> .List </base-classes>
                         <virtual-bases> .Set </virtual-bases>
                         <cenv> .Map </cenv>
                         <ctypes> .Map </ctypes>
                         <cenums> .Map </cenums>
                         <initializers> .Map </initializers>
                         <non-static-data-members> .List </non-static-data-members>
                         <function-members> .List </function-members>
                         <variant-members> .Set </variant-members>
                         <conversion-functions> .List </conversion-functions>
                         <access> .Map </access>
                         <base-access> .Map </base-access>
                         <access-specifier> .K </access-specifier>
                         <sizeof> 0 </sizeof>
                         <align> 1 </align>
                         <dsize> 0 </dsize>
                         <nvsize> -1 </nvsize>
                         <nvalign> -1 </nvalign>
                    </class>
               </classes>

               <cpp-enums>
                    <cppenum multiplicity="*" type="Map">
                         <enum-id> .K </enum-id>
                         <enum-type> .K </enum-type>
                         <scoped> false </scoped>
                         <enumerators> .Map </enumerators>
                         <enum-complete> false </enum-complete>
                         <enum-opaque> true </enum-opaque>
                         <enum-min> 0 </enum-min>
                         <enum-max> 0 </enum-max>
                    </cppenum>
               </cpp-enums>

               <when-odr-used> .Map </when-odr-used>

          </tu>
     </translation-units>
   </global>

endmodule
