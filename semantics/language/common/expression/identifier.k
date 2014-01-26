module C-COMMON-EXPRESSION-IDENTIFIER-SYNTAX
     syntax K ::= "populateFromGlobal"
endmodule

module C-COMMON-EXPRESSION-IDENTIFIER
     imports C-COMMON-EXPRESSION-IDENTIFIER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.1}{2}}}{
     An identifier is a primary expression, provided it has been declared as
     designating an object (in which case it is an lvalue) or a function (in
     which case it is a function designator).
     }*/
     rule [lookup]:
          <k> X:Id => lv(Loc, T) ...</k>
          <env>... X |-> Loc:SymLoc ...</env>
          <types>... X |-> T:Type ...</types>
          [structural]
          
     rule [populateFromGlobal]:
          <k> populateFromGlobal => . ...</k>
          <currTU> Tu:K </currTU>
          <tu-id> Tu </tu-id>
          <genv> G:Map </genv> 
          <gtypes> GT:Map </gtypes> 
          <gstructs> GS:Map </gstructs> 
          <env> _ => G </env>
          <types> _ => GT </types>
          <structs> _ => GS </structs>
          [structural]

endmodule

