module C-EXPR-IDENTIFIER
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.1}{2}}}{
     An identifier is a primary expression, provided it has been declared as
     designating an object (in which case it is an lvalue) or a function (in
     which case it is a function designator).
     }*/
     rule <k> X:CId => lv(lnew(Base), T) ...</k>
          <env>... X |-> Base:SymBase ...</env>
          <types>... X |-> T:Type ...</types>
          [structural]

     // TODO(chathhorn): this is very crude (in particular, it conflates
     // aggregates and unions with their first member) and should be refactored
     // out at some point. In particular, we should probably model sub-objects
     // in the memory (reading bytes should be a special corner case, not the
     // case we optimize for) and maybe keep this info there.
     rule <k> instantiate(Loc:SymLoc, T:Type)
               => read(Loc, addModifiers(Prov, T))
          ...</k>
          <provenance>... Loc |-> set(Prov:Set) ...</provenance>
          when notBool isRestrictType(T)
          [structural]
     rule <k> instantiate(Loc:SymLoc, T:Type)
               => read(Loc, addModifiers(Prov SetItem(basedOn(base(Loc))), T))
          ...</k>
          <provenance>... Loc |-> set(Prov:Set) ...</provenance>
          when isRestrictType(T)
          [structural]
     rule <k> instantiate(Loc:SymLoc, T:Type)
               => read(Loc, T)
          ...</k>
          <provenance> Prov:Map </provenance>
          when notBool isRestrictType(T)
               andBool notBool (Loc in keys(Prov))
          [structural]
     rule <k> instantiate(Loc:SymLoc, T:Type)
               => read(Loc, addProvenance(basedOn(base(Loc)), T))
          ...</k>
          <provenance> Prov:Map </provenance>
          when isRestrictType(T)
               andBool notBool (Loc in keys(Prov))
          [structural]
endmodule

