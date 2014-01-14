module C-EXPRESSION-IDENTIFIER-SYNTAX
     syntax K ::= "populateFromGlobal"
endmodule

module C-EXPRESSION-IDENTIFIER
     imports C-EXPRESSION-IDENTIFIER-SYNTAX
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
          <genv>... Tu |-> map(G:Map) ...</genv> 
          <env> _ => G </env>
          <gtypes>... Tu |-> map(GT:Map) ...</gtypes> 
          <types> _ => GT </types>
          <gstructs> GS:Map </gstructs> 
          <structs> _ => GS </structs>
          [structural]

endmodule

