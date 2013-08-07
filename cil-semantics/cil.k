// vim: ts=2 sw=2:
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
    <resultValue multiplicity="?"> .K </resultValue>
    <frame multiplicity="?">
      <k> $PGM:File ~> callMain </k>
      <frame-fun-id> Null </frame-fun-id> // Ptr
      <env> .Map </env> // Map{CId, lv(Type, Ptr)}
    </frame>
    <frame-stack> .List </frame-stack>  // List{<frame> ... </frame>}
    <funs>
      <fun multiplicity="*">
        <fun-id> .K </fun-id> // Ptr
        <fun-type> void </fun-type> // Type
        <formals> .Params </formals>
        <body> .K </body> // FunBody
        <labels> .Map </labels> // Map{Label, Stmt}
      </fun>
    </funs>
    <typedefs> .Map </typedefs> // Map{CId, Type}
    <global-env> .Map </global-env> // Map{CId, Ptr}
    <phase> initializing </phase> // Phase
    <tus>
      <tu multiplicity="*">
        <tu-id> .K </tu-id> // TransUnit
        <tu-env> .Map </tu-env> // Map{CId, Ptr}
      </tu>
    </tus>
    <aggregates> // structs and unions
     <aggregate multiplicity="*">
       <agg-id> .K </agg-id> // TypeId
       <size> 0 </size>
       <fields>
          <field multiplicity="*">
               <field-id> .K </field-id> // CId
               <field-type> .K </field-type> // Type
               <offset> 0 </offset> 
          </field>
       </fields>
     </aggregate>
    </aggregates>
    <heap>
      <object multiplicity="*">
        <base-ptr> Null </base-ptr>
        <object-type> void </object-type>
        <bytes> .Map </bytes> // Map{Nat, ByteValue}
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
    <propagate-constants>
      <propagate-constants-enabled> false </propagate-constants-enabled>
      <propagate-constants-stmts> .Stmts </propagate-constants-stmts>
      <after-stmts> .Stmts </after-stmts>
      <constant-table> .Map </constant-table> // Map{CId, Value}
    </propagate-constants>

  syntax KResult ::= TypedValue
                   | NoConversionLeftValue
endmodule

