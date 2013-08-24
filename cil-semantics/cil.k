// vim: ts=2 sw=2:
require "cil-decl.k"
require "cil-exp.k"
require "cil-stmt.k"
require "cil-implementation.k"
require "cil-typing.k"
require "cil-lib.k"

module CIL
  imports CIL-DECL
  imports CIL-EXP
  imports CIL-STMT
  imports CIL-IMPLEMENTATION
  imports CIL-TYPING
  imports CIL-LIB

  syntax K ::= "wrapper" "(" KList ")"
  configuration
    <final-computation multiplicity="?"> .K </final-computation>
    <result-value multiplicity="?"> .K </result-value>
    <error-cell multiplicity="?"> .K </error-cell>
    <strings> .Map </strings> // Map{String, Ptr}
    <external> .Set </external> // Set{CId}. Symbols with external linkage.
    <frame multiplicity="*">
      <k> $PGM:File ~> callMain </k>
      <frame-fun-id> Null </frame-fun-id> // Ptr
      <frame-fun-va-args> .K </frame-fun-va-args>
      <env> .Map </env> // Map{CId, lv(Type, Ptr)|Type}
    </frame>
    <frame-stack> .List </frame-stack>  // List{<frame> ... </frame>}
    <funs>
      <fun multiplicity="*">
        <fun-id> .K </fun-id> // Ptr
        <fun-type> void </fun-type> // Type
        <formals> .Params </formals>
        <body> .K </body> // FunBody
        <labels> .Map </labels> // Map{Label, Stmt}
        // For lazy label generation.
        <labels-generated> false </labels-generated>
      </fun>
    </funs>
    <global-env> .Map </global-env> // Map{CId, Ptr}
    //<phase> initializing </phase> // Phase
    <phase> tu("unknown") </phase> // Phase
    <tus>
      <tu multiplicity="+">
        <tu-id> tu("unknown") </tu-id> // TransUnit
        <tu-env> .Map </tu-env> // Map{CId, Ptr}
        <internal> .Set </internal> // Set{CId}. Symbols with internal linkage.
      </tu>
    </tus>
    <aggregates> // structs and unions
     <aggregate multiplicity="*">
       <agg-id> .K </agg-id> // TypeId
       <size> 0 </size>
       <fields>
          <field multiplicity="*">
               <field-id> .K </field-id> // CId
               <field-pos> 0 </field-pos> // The pos it appeared in the decl.
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
      <make-goto-table-tasks>
        <make-goto-table-task multiplicity="*">
          <make-goto-table-stmts> .Stmts </make-goto-table-stmts>
          <make-goto-table-cont> .Stmts </make-goto-table-cont>
        </make-goto-table-task>
      </make-goto-table-tasks>
    </make-goto-table>
    <propagate-constants>
      <propagate-constants-enabled> false </propagate-constants-enabled>
      <propagate-constants-stmts> .Stmts </propagate-constants-stmts>
      <after-stmts> .Stmts </after-stmts>
      <constant-table> .Map </constant-table> // Map{CId, Value}
    </propagate-constants>

  syntax KResult ::= TypedValue
                   | NoConversionLeftValue
                   | NormType
endmodule

