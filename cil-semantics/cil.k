// vim: ts=2 sw=2:
require "builtins/list.k"
require "builtins/map.k"
require "builtins/set.k"

require "cil-syntax.k"
require "cil-common.k"
require "cil-decl.k"
require "cil-exp.k"
require "cil-stmt.k"
require "cil-typing.k"
require "cil-implementation.k"
require "cil-lib.k"


module CIL
  imports LIST
  imports MAP
  imports SET

  imports CIL-SYNTAX
  imports CIL-COMMON
  imports CIL-DECL
  imports CIL-EXP
  imports CIL-STMT
  imports CIL-TYPING
  imports CIL-IMPLEMENTATION
  imports CIL-LIB


  configuration
    <final-computation multiplicity="?"> .K </final-computation>
    <result-value multiplicity="?"> .K </result-value>
    <error-cell multiplicity="?"> .K </error-cell>
    <strings> .Map </strings> // Map{String, Ptr}
    <external> .Set </external> // Set{CId}. Symbols with external linkage.
    //<frame multiplicity="*">
    <frame multiplicity="?">
      <k> $PGM:File ~> callMain </k>
      //<k> $PGM:File </k>
      <frame-fun-id> Null </frame-fun-id> // Ptr
      <frame-fun-va-args> .K </frame-fun-va-args>
      <env> .Map </env> // Map{CId, lv(Type, Ptr)|Type}
      <locals> .Set </locals> // Set{Ptr}
    </frame>
    <frame-stack list="">  // List{<frame> ... </frame>}
       <stacked-frame>
         .Bag
       </stacked-frame>
    </frame-stack>
    <funs map="">
      <fun multiplicity="*">
        <fun-id key=""> .K </fun-id> // Ptr
        <fun-type> void </fun-type> // Type
        <formals> .Params </formals>
        <body> .K </body> // FunBody
        <labels> .Map </labels> // Map{Label, Stmt}
        // For lazy label generation.
        <labels-generated> false </labels-generated>
      </fun>
    </funs>
    <global-env> .Map </global-env> // Map{CId, Ptr}
//    //<phase> initializing </phase> // Phase
    <phase> tu("unknown"):>K </phase> // Phase
    <tus map="">
      <tu multiplicity="+">
        <tu-id key=""> tu("unknown") </tu-id> // TransUnit
        <tu-env> .Map </tu-env> // Map{CId, Ptr}
        <internal> .Set </internal> // Set{CId}. Symbols with internal linkage.
      </tu>
    </tus>
    <aggregates map=""> // structs and unions
      <aggregate multiplicity="*">
        <agg-id key=""> .K </agg-id> // TypeId
        <size> 0 </size>
        <fields map="">
          <field multiplicity="*">
            <field-id key=""> .K </field-id> // CId
            <field-pos> 0 </field-pos> // The pos it appeared in the decl.
            <field-type> .K </field-type> // Type
            <offset> 0 </offset> 
          </field>
        </fields>
      </aggregate>
    </aggregates>
    <heap map="">
      <object multiplicity="*">
        <base-ptr key=""> Null </base-ptr>
        //<object-type> void </object-type>
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
    <make-case-labels> .Map </make-case-labels>

  syntax KResult ::= TypedValue
                   | NoConversionLeftValue
                   | NormType

  // TODO(AndreiS): remove hacks because tokens are not labels in the java
  // rewrite engine
  rule normParens'(KI:KItem) => KI
  when isBuiltin(KI)
  rule normPtrs'(KI:KItem) => KI
  when isBuiltin(KI)
endmodule

