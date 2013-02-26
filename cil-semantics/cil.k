require "cil-decl.k"
require "cil-exp.k"
require "cil-stmt.k"
require "cil-implementation.k"


module CIL
  imports CIL-DECL
  imports CIL-EXP
  imports CIL-STMT
  imports CIL-IMPLEMENTATION

  syntax K ::= "wrapper" "(" KList ")"
  configuration
    <frame>
      <k> $PGM:File ~> main(.Exps) </k>
      <frame-fun-id> .K </frame-fun-id> // CId
      <env> .Map </env> // Map{CId, Ptr}
      <type-env> .Map </type-env> // Map{CId, Type}
    </frame>
    <frame-stack> .List </frame-stack>  // List{<frame> ... </frame>}
    <funs>
      <fun multiplicity="*">
        <fun-id> .K </fun-id> // CId
        <fun-type> void </fun-type>
        <formals> .Params </formals>
        <body> .K </body> // FunBody
        <labels> .Map </labels> // Map{Label, Stmt}
      </fun>
    </funs>
    <heap>
      <object multiplicity="*">
        <base-ptr> Null </base-ptr>
        <object-type> void </object-type>
        <bytes> .Map </bytes> // Map{Nat, Nat}
      </object>
    </heap>
    <make-goto-table>
      <make-goto-table-enabled> false </make-goto-table-enabled>
      <make-goto-table-task multiplicity="*">
        <make-goto-table-stmts> .Stmts </make-goto-table-stmts>
        <make-goto-table-while-continuation>
          .Stmts
        </make-goto-table-while-continuation>
      </make-goto-table-task>
    </make-goto-table>

  syntax KResult ::= TypedValue
                   | NoConverionLeftValue
                   | BasicType
                   | PtrType
endmodule

