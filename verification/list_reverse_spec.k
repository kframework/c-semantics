require "c-verifier.k"

module REVERSE-SPEC
imports C-VERIFIER

rule [loop-inv]:
  <global>
    <mem>...  
      MEM:Map
      AX @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(PX:CanonicalSymLoc => NullPointer, 0, 0), 8)
        1 |-> piece(subObject(PX:CanonicalSymLoc => NullPointer, 1, 1), 8)
        2 |-> piece(subObject(PX:CanonicalSymLoc => NullPointer, 2, 2), 8)
        3 |-> piece(subObject(PX:CanonicalSymLoc => NullPointer, 3, 3), 8), .Map)
      AP @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(PP:CanonicalSymLoc => ?PP2:CanonicalSymLoc, 0, 0), 8)
        1 |-> piece(subObject(PP:CanonicalSymLoc => ?PP2:CanonicalSymLoc, 1, 1), 8)
        2 |-> piece(subObject(PP:CanonicalSymLoc => ?PP2:CanonicalSymLoc, 2, 2), 8)
        3 |-> piece(subObject(PP:CanonicalSymLoc => ?PP2:CanonicalSymLoc, 3, 3), 8), .Map)
    (
      list(PX:CanonicalSymLoc)(LX:List)
      list(PP:CanonicalSymLoc)(LP:List)
    =>
      list(?PP2:CanonicalSymLoc)(?LP2:List)
    )
    ...</mem>
    <functions> FUNCTIONS:Map </functions>
    <external-types> EXTERNALTYPES:Map </external-types>
    <external-defs> EXTERNALDEFS:Map </external-defs>
    <structs> STRUCTS:Map </structs>
    <linkings> LINKINGS:Map </linkings>
    <translation-units> TRANSLATIONUNITS:Bag </translation-units>
    <main-tu> _:Set </main-tu>
  </global>
  <T>
    <files>
      <file-commands> .K </file-commands>
    </files>
    <error-cell-wrapper> .Bag </error-cell-wrapper>
    <status> mainCalled </status>
    <exec>
      <restrict> .Map </restrict>
      <activeBlocks> .Map </activeBlocks>
      <malloced> _:Map => ?_:Map </malloced>
      <next-malloced> (_:Int => ?_:Int) @ alloc </next-malloced>
      <threads>
        <thread>
          <thread-id> 0 </thread-id>
          <buffer> .List </buffer>
          <k> 
            'loopMarked(.KList) ~> 
            'While('_!=_('Identifier("x"),, 'Cast('Specifier('list(ListItem('Void(.KList))  )),, 'PointerType('Specifier('list(.List)),, 'JustBase(.KList)),, 'tv(0,, 't(SetItem(IntegerConstant),, 'int(.KList))))),,
                   'BlockStatement('Block(3,, 'list(.List),, 'list(ListItem('CodeLoc('BlockStatement('Block(4,, 'list(.List),, 'list(
                     ListItem('CodeLoc('DeclarationDefinition('InitNameGroup('Specifier('list(ListItem('StructRef('Identifier("listNode")))  )),, 'list(ListItem('InitName('Name('Identifier("y"),, 'PointerType('Specifier('list(.List)),, 'JustBase(.KList))),, 'NoInit(.KList)))  ))),, _:CabsLoc))  // 'CabsLoc(String(#""list.c""),, Int(#"14"),, Int(#"5"),, Int(#"0"))
                     ListItem('CodeLoc('Computation('_:=_('Identifier("y"),, '_._('*_('Identifier("x")),, 'Identifier("next")))),, _:CabsLoc))  // 'CabsLoc(String(#""list.c""),, Int(#"16"),, Int(#"5"),, Int(#"0"))
                     ListItem('CodeLoc('Computation('_:=_('_._('*_('Identifier("x")),, 'Identifier("next")),, 'Identifier("p"))),, _:CabsLoc))  // 'CabsLoc(String(#""list.c""),, Int(#"17"),, Int(#"5"),, Int(#"0"))
                     ListItem('CodeLoc('Computation('_:=_('Identifier("p"),, 'Identifier("x"))),, _:CabsLoc))  // 'CabsLoc(String(#""list.c""),, Int(#"18"),, Int(#"5"),, Int(#"0"))
                     ListItem('CodeLoc('Computation('_:=_('Identifier("x"),, 'Identifier("y"))),, _:CabsLoc))  // 'CabsLoc(String(#""list.c""),, Int(#"19"),, Int(#"5"),, Int(#"0"))
                   ))),, _:CabsLoc))  )))) // 'CabsLoc(String(#""list.c""),, Int(#"13"),, Int(#"27"),, Int(#"0"))
          =>
            .K
          ...</k>
          <initializing> 0 </initializing>
          <duration> auto(0) </duration>
//        <final-computation> ... </final-computation>
          <thread-local>...
            <control>
              <control-details>
                <block-stack> .List </block-stack>
                <curr-object> .List </curr-object>
                <incomplete-length> 0 </incomplete-length>
                <should-init> true </should-init>
                <decl-type-holder> .K </decl-type-holder>
                <loop-stack> _:List </loop-stack>
                <type-wrapper> .Bag </type-wrapper>
                <curr-subobject> .List </curr-subobject>
                <saved-init> .K </saved-init>
                <locs-written> .List </locs-written>
                <local>
                  <types>
                    Identifier("x")                         |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))
                    Identifier("p")                         |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))
                    //
                  '_Map_(
                    Identifier("reverse")                   |-> t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))))) 
                  ,,Identifier("bubble_sort")               |-> t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))))) 
                  ,,Identifier("insertion_sort")            |-> t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))))) 
                  ,,Identifier("merge_sort")                |-> t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))))) 
                  ,,Identifier("append")                    |-> t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))) ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))))) 
                  ,,Identifier("quicksort")                 |-> t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))))) 
                  ,,Identifier("main")                      |-> t(.Set, functionType(t(.Set, int), ListItem(t(.Set, void)))) 
                    //
                  ,,typedef(Identifier("div_t"))            |-> 't(.Set,, 'structType('global('Identifier("div_t_"),,  "list.c"))) 
                  ,,typedef(Identifier("ldiv_t"))           |-> 't(.Set,, 'structType('global('Identifier("ldiv_t_"),, "list.c"))) 
                  ,,typedef(Identifier("max_align_t"))      |-> 't(.Set,, 'signed-char(.KList))
                  ,,typedef(Identifier("ptrdiff_t"))        |-> 't(.Set,, 'int(.KList)) 
                  ,,typedef(Identifier("size_t"))           |-> 't(.Set,, 'unsigned-int(.KList)) 
                  ,,typedef(Identifier("wchar_t"))          |-> 't(.Set,, 'int(.KList))
                    //
                  ,,Identifier("#incomingArgumentsArray")   |-> 't(.Set,, 'arrayType('t(.Set,, 'pointerType('t(.Set,, 'signed-char(.KList)))),, 2))
                    //
                  ,,Identifier("free")                      |-> 't(.Set,, 'functionType('t(.Set,, 'void(.KList)),, ListItem('t(.Set,, 'pointerType('t(.Set,, 'void(.KList)))))  )) 
                  ,,Identifier("malloc")                    |-> 't(.Set,, 'functionType('t(.Set,, 'pointerType('t(.Set,, 'void(.KList)))),, ListItem('t(.Set,, 'unsigned-int(.KList)))  )) 
                    //
                  ,,Identifier("realloc")                   |-> 't(.Set,, 'functionType('t(.Set,, 'pointerType('t(.Set,, 'void(.KList)))),, ListItem('t(.Set,, 'pointerType('t(.Set,, 'void(.KList))))) ListItem('t(.Set,, 'unsigned-int(.KList)))  )) 
                  ,,Identifier("calloc")                    |-> 't(.Set,, 'functionType('t(.Set,, 'pointerType('t(.Set,, 'void(.KList)))),, ListItem('t(.Set,, 'unsigned-int(.KList))) ListItem('t(.Set,, 'unsigned-int(.KList)))  ))
                  ,,Identifier("exit")                      |-> 't(.Set,, 'functionType('t(.Set,, 'void(.KList)),, ListItem('t(.Set,, 'int(.KList)))  )) 
                  ,,Identifier("__debug")                   |-> 't(.Set,, 'functionType('t(.Set,, 'void(.KList)),, ListItem('t(.Set,, 'int(.KList)))  )) 
                  ,,Identifier("srand")                     |-> 't(.Set,, 'functionType('t(.Set,, 'void(.KList)),, ListItem('t(.Set,, 'unsigned-int(.KList)))  )) 
                  ,,Identifier("rand")                      |-> 't(.Set,, 'functionType('t(.Set,, 'int(.KList)),, ListItem('t(.Set,, 'void(.KList)))  )) 
                  ,,Identifier("abort")                     |-> 't(.Set,, 'functionType('t(.Set,, 'void(.KList)),, ListItem('t(.Set,, 'void(.KList)))  )) 
                  ,,Identifier("atoi")                      |-> 't(.Set,, 'functionType('t(.Set,, 'int(.KList)),, ListItem('t(.Set,, 'pointerType('t(SetItem(Const),, 'signed-char(.KList)))))  )) 
                  )
                  </types>
                  <nesting-depth> 0 </nesting-depth>
                  <formatting-wrapper> .Bag </formatting-wrapper>
                  <compound-lit-map> .Map </compound-lit-map>
                  <local-vars> ListItem(Identifier("p")) </local-vars>
                  <local-addresses> SetItem(AX:Int @ auto(0)) SetItem(AP:Int @ auto(0)) </local-addresses>
                  <env>
                    Identifier("x")                         |-> AX:Int @ auto(0)
                    Identifier("p")                         |-> AP:Int @ auto(0)
                    //
                  '_Map_(
                    Identifier("reverse")                   |-> 0 @ static("list.c") 
                  ,,Identifier("bubble_sort")               |-> 1 @ static("list.c") 
                  ,,Identifier("insertion_sort")            |-> 2 @ static("list.c") 
                  ,,Identifier("merge_sort")                |-> 3 @ static("list.c") 
                  ,,Identifier("append")                    |-> 4 @ static("list.c") 
                  ,,Identifier("quicksort")                 |-> 5 @ static("list.c") 
                  ,,Identifier("main")                      |-> 6 @ static("list.c") 
                    //
                  ,,Identifier("#incomingArgumentsArray")   |-> 0  @ argv
                    //
                  ,,Identifier("free")                      |-> 14 @ static("builtin") 
                  ,,Identifier("malloc")                    |-> 16 @ static("builtin") 
                    //
                  ,,Identifier("realloc")                   |-> 1  @ link("list.c") 
                  ,,Identifier("calloc")                    |-> 3  @ link("list.c")   
                  ,,Identifier("exit")                      |-> 4  @ link("list.c") 
                  ,,Identifier("__debug")                   |-> 5  @ link("list.c") 
                  ,,Identifier("srand")                     |-> 6  @ link("list.c") 
                  ,,Identifier("rand")                      |-> 7  @ link("list.c") 
                  ,,Identifier("abort")                     |-> 8  @ link("list.c") 
                  ,,Identifier("atoi")                      |-> 9  @ link("list.c") 
                  )
                  </env>
                  <block-history> ListItem(1) </block-history>
                </local>
              </control-details>
              <curr-program-loc> _:CabsLoc => ?_:CabsLoc </curr-program-loc>
              <curr-function-params> ListItem(Identifier("x")) </curr-function-params>
              <curr-function> Identifier("reverse") </curr-function>
              <curr-tu> "list.c" </curr-tu>
            </control>
            <call-stack> _:List </call-stack>
          ...</thread-local>
        </thread>
      </threads>
      <effective-types> _:Map </effective-types>
      <rand-nat> _:KItem </rand-nat>
      <next-thread-id> _:KItem </next-thread-id>
      <thread-info>
        <thread-status> _:Map </thread-status>
        <mutexes> _:Map </mutexes>
        <glocks> _:List </glocks>
      </thread-info>
    </exec>
    <input> _:List </input>
    <output> _:List </output>
    <result-value> _:K </result-value>
    <options> _:Set </options>
  </T>
ensures  ?LP2 ==K rev(LX) LP

rule [func-reverse]:
//<global>
    <mem>...  
      MEM:Map
    (
      list( LP1:CanonicalSymLoc)(L:List)
    =>
      list(?LP2:CanonicalSymLoc)(rev(L))
    )
    ...</mem>
    <functions> FUNCTIONS:Map </functions>
    <external-types> EXTERNALTYPES:Map </external-types>
    <external-defs> EXTERNALDEFS:Map </external-defs>
    <structs> STRUCTS:Map </structs>
    <linkings> LINKINGS:Map </linkings>
    <translation-units> TRANSLATIONUNITS:Bag </translation-units>
//  <main-tu> _:Set </main-tu>
//</global>
//<T>...
    <files>
      <file-commands> .K </file-commands>
    </files>
    <error-cell-wrapper> .Bag </error-cell-wrapper>
    <status> mainCalled </status>
//  <exec>...
      <restrict> .Map </restrict>
      <activeBlocks> .Map </activeBlocks>
      <malloced> _:Map => ?_:Map </malloced>
      <next-malloced> (_:Int => ?_:Int) @ alloc </next-malloced>
      <threads>
        <thread>...
          <thread-id> 0 </thread-id>
          <buffer> .List </buffer>
          <k> 
            Call1(
                tv(loc(0 @ static("list.c"), 0), // reverse
                    t(.Set, pointerType(t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))))))),
                rvlist(
                    ListItem(tv(LP1:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))))))
          =>
            tv(?LP2:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
          ...</k>
          <initializing> 0 </initializing>
          <duration> auto(0) </duration>
//        <thread-local>...
//          <control>...
//            <control-details>...
                <type-wrapper> .Bag </type-wrapper>
                <curr-subobject> .List </curr-subobject>
                <locs-written> _:List => .List </locs-written>
//              <local>...
//                <types> ... </types>
                  <formatting-wrapper> .Bag </formatting-wrapper>
//                <env> ... </env>
//              ...</local>
//            ...</control-details>
              <curr-program-loc> _ => ?_ </curr-program-loc>
              <curr-function> _:CId </curr-function>
//          ...</control>
//          <call-stack> _:List </call-stack>
//        ...</thread-local>
        ...</thread>
      </threads>
//  ...</exec>
//...</T>

endmodule
