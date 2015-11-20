require "c-verifier.k"

module BUBBLE-SORT-SPEC
imports C-VERIFIER

rule [outer-loop-inv]:
  <global>
    <mem>...  
      MEM:Map
      AX @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(PX:CanonicalSymLoc, 0, 0), 8)
        1 |-> piece(subObject(PX:CanonicalSymLoc, 1, 1), 8)
        2 |-> piece(subObject(PX:CanonicalSymLoc, 2, 2), 8)
        3 |-> piece(subObject(PX:CanonicalSymLoc, 3, 3), 8), .Map)
      AC @ auto(0) |-> object(t(.Set, int), 4, 
        0 |-> piece(C0:Int => ?_:Int, 8) 
        1 |-> piece(C1:Int => ?_:Int, 8) 
        2 |-> piece(C2:Int => ?_:Int, 8) 
        3 |-> piece(C3:Int => ?_:Int, 8), .Map)
    (
      lseg(PX:CanonicalSymLoc, NullPointer)(LX:List)
    =>
      lseg(PX:CanonicalSymLoc, NullPointer)(?LX2:List)
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
            'While('Identifier("change"),, 
                   'BlockStatement('Block(11,, 'list(.List),, 'list(ListItem('CodeLoc('BlockStatement('Block(12,, 'list(.List),, 'list(
                     ListItem('CodeLoc('DeclarationDefinition('InitNameGroup('Specifier('list(ListItem('StructRef('Identifier("listNode")))  )),, 'list(ListItem('InitName('Name('Identifier("y"),, 'PointerType('Specifier('list(.List)),, 'JustBase(.KList))),, 'NoInit(.KList)))  ))),, _:CabsLoc)) 
                     ListItem('CodeLoc('Computation('_:=_('Identifier("change"),, 'tv(0,, 't(SetItem(IntegerConstant),, 'int(.KList))))),, _:CabsLoc)) 
                     ListItem('CodeLoc('Computation('_:=_('Identifier("y"),, 'Identifier("x"))),, _:CabsLoc)) 
                     ListItem('CodeLoc(
                        'While('_!=_('_._('*_('Identifier("y")),, 'Identifier("next")),, 'Cast('Specifier('list(ListItem('Void(.KList))  )),, 'PointerType('Specifier('list(.List)),, 'JustBase(.KList)),, 'tv(0,, 't(SetItem(IntegerConstant),, 'int(.KList))))),, 
                               'BlockStatement('Block(13,, 'list(.List),, 'list(ListItem('CodeLoc('BlockStatement('Block(14,, 'list(.List),, 'list(
                                 ListItem('CodeLoc(
                                    'IfThenElse('_>_('_._('*_('Identifier("y")),, 'Identifier("val")),, '_._('*_('_._('*_('Identifier("y")),, 'Identifier("next"))),, 'Identifier("val"))),, 
                                                'BlockStatement('Block(16,, 'list(.List),, 'list(ListItem('CodeLoc('BlockStatement('Block(17,, 'list(.List),, 'list(
                                                  ListItem('CodeLoc('DeclarationDefinition('InitNameGroup('Specifier('list(ListItem('Int(.KList))  )),, 'list(ListItem('InitName('Name('Identifier("temp"),, 'JustBase(.KList)),, 'NoInit(.KList)))  ))),, _:CabsLoc)) 
                                                  ListItem('CodeLoc('Computation('_:=_('Identifier("change"),, 'tv(1,, 't(SetItem(IntegerConstant),, 'int(.KList))))),, _:CabsLoc)) 
                                                  ListItem('CodeLoc('Computation('_:=_('Identifier("temp"),, '_._('*_('Identifier("y")),, 'Identifier("val")))),, _:CabsLoc)) 
                                                  ListItem('CodeLoc('Computation('_:=_('_._('*_('Identifier("y")),, 'Identifier("val")),, '_._('*_('_._('*_('Identifier("y")),, 'Identifier("next"))),, 'Identifier("val")))),, _:CabsLoc)) 
                                                  ListItem('CodeLoc('Computation('_:=_('_._('*_('_._('*_('Identifier("y")),, 'Identifier("next"))),, 'Identifier("val")),, 'Identifier("temp"))),, _:CabsLoc))  
                                                ))),, _:CabsLoc))  ))),, 
                                                'BlockStatement('Block(15,, 'list(.List),, 'list(ListItem('CodeLoc('Nop(.KList),, _:CabsLoc))  ))))
                                 ,, _:CabsLoc))
                                 ListItem('CodeLoc('Computation('_:=_('Identifier("y"),, '_._('*_('Identifier("y")),, 'Identifier("next")))),, _:CabsLoc))
                               ))),, _:CabsLoc))  ))))
                     ,, _:CabsLoc))  
                   ))),, _:CabsLoc))  ))))
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
                    Identifier("change")                    |-> t(.Set, int)
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
                  <local-vars> ListItem(Identifier("change")) </local-vars>
                  <local-addresses> SetItem(AX:Int @ auto(0)) SetItem(AC:Int @ auto(0)) </local-addresses>
                  <env>
                    Identifier("x")                         |-> AX:Int @ auto(0)
                    Identifier("change")                    |-> AC:Int @ auto(0)
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
                  <block-history> ListItem(6) </block-history>
                </local>
              </control-details>
              <curr-program-loc> _:CabsLoc => ?_:CabsLoc </curr-program-loc>
              <curr-function-params> ListItem(Identifier("x")) </curr-function-params>
              <curr-function> Identifier("bubble_sort") </curr-function>
              <curr-tu> "list.c" </curr-tu>
            </control>
            <call-stack> _:List </call-stack>
          ...</thread-local>
        </thread>
      </threads>
    //<effective-types> _:Map </effective-types>
    //<rand-nat> _:KItem </rand-nat>
    //<next-thread-id> _:KItem </next-thread-id>
    //<thread-info>
    //  <thread-status> _:Map </thread-status>
    //  <mutexes> _:Map </mutexes>
    //  <glocks> _:List </glocks>
    //</thread-info>
    </exec>
    <input> _:List </input>
    <output> _:List </output>
    <result-value> _:K </result-value>
    <options> _:Set </options>
  </T>
//
requires PX =/=K NullPointer
 andBool ( sorted(LX) orBool ii(C3,C2,C1,C0) =/=K 0 )
 andBool ( ii(C3,C2,C1,C0) ==K 0 orBool ii(C3,C2,C1,C0) ==K 1 ) // truth value
//
ensures  sorted(?LX2)
 andBool list2set(LX) ==K list2set(?LX2)


rule [inner-loop-inv]:
  <global>
    <mem>...  
      MEM:Map
      AX @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(PX:CanonicalSymLoc, 0, 0), 8)
        1 |-> piece(subObject(PX:CanonicalSymLoc, 1, 1), 8)
        2 |-> piece(subObject(PX:CanonicalSymLoc, 2, 2), 8)
        3 |-> piece(subObject(PX:CanonicalSymLoc, 3, 3), 8), .Map)
      AY @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(loc(PY:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))) => ?_:CanonicalSymLoc, 0, 0), 8)
        1 |-> piece(subObject(loc(PY:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))) => ?_:CanonicalSymLoc, 1, 1), 8)
        2 |-> piece(subObject(loc(PY:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))) => ?_:CanonicalSymLoc, 2, 2), 8)
        3 |-> piece(subObject(loc(PY:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))) => ?_:CanonicalSymLoc, 3, 3), 8), .Map)
      AC @ auto(0) |-> object(t(.Set, int), 4, 
        0 |-> piece(C0:Int => ?NC0:Int, 8) 
        1 |-> piece(C1:Int => ?NC1:Int, 8) 
        2 |-> piece(C2:Int => ?NC2:Int, 8) 
        3 |-> piece(C3:Int => ?NC3:Int, 8), .Map)
    (
      // lseg(x,y)
      lseg(PX:CanonicalSymLoc,
           loc(PY:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))))(LXY:List)
      // y->ynext
      PY:Int @ alloc |-> object(t(.Set, no-type), 8,
        0 |-> piece(V0:Int, 8) 
        1 |-> piece(V1:Int, 8) 
        2 |-> piece(V2:Int, 8) 
        3 |-> piece(V3:Int, 8) 
        4 |-> piece(subObject(PYNext:CanonicalSymLoc, 0, 0), 8)
        5 |-> piece(subObject(PYNext:CanonicalSymLoc, 1, 1), 8)
        6 |-> piece(subObject(PYNext:CanonicalSymLoc, 2, 2), 8)
        7 |-> piece(subObject(PYNext:CanonicalSymLoc, 3, 3), 8)
       ,0 |-> t(.Set, int)
        4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
      // lseg(ynext,null)
      lseg(PYNext:CanonicalSymLoc, NullPointer)(LYNext:List)
    =>
      // lseg(x,null)
      lseg(PX:CanonicalSymLoc, NullPointer)(?LX2:List)
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
            'While('_!=_('_._('*_('Identifier("y")),, 'Identifier("next")),, 'Cast('Specifier('list(ListItem('Void(.KList))  )),, 'PointerType('Specifier('list(.List)),, 'JustBase(.KList)),, 'tv(0,, 't(SetItem(IntegerConstant),, 'int(.KList))))),, 
                   'BlockStatement('Block(13,, 'list(.List),, 'list(ListItem('CodeLoc('BlockStatement('Block(14,, 'list(.List),, 'list(
                     ListItem('CodeLoc(
                        'IfThenElse('_>_('_._('*_('Identifier("y")),, 'Identifier("val")),, '_._('*_('_._('*_('Identifier("y")),, 'Identifier("next"))),, 'Identifier("val"))),, 
                                    'BlockStatement('Block(16,, 'list(.List),, 'list(ListItem('CodeLoc('BlockStatement('Block(17,, 'list(.List),, 'list(
                                      ListItem('CodeLoc('DeclarationDefinition('InitNameGroup('Specifier('list(ListItem('Int(.KList))  )),, 'list(ListItem('InitName('Name('Identifier("temp"),, 'JustBase(.KList)),, 'NoInit(.KList)))  ))),, _:CabsLoc)) 
                                      ListItem('CodeLoc('Computation('_:=_('Identifier("change"),, 'tv(1,, 't(SetItem(IntegerConstant),, 'int(.KList))))),, _:CabsLoc)) 
                                      ListItem('CodeLoc('Computation('_:=_('Identifier("temp"),, '_._('*_('Identifier("y")),, 'Identifier("val")))),, _:CabsLoc)) 
                                      ListItem('CodeLoc('Computation('_:=_('_._('*_('Identifier("y")),, 'Identifier("val")),, '_._('*_('_._('*_('Identifier("y")),, 'Identifier("next"))),, 'Identifier("val")))),, _:CabsLoc)) 
                                      ListItem('CodeLoc('Computation('_:=_('_._('*_('_._('*_('Identifier("y")),, 'Identifier("next"))),, 'Identifier("val")),, 'Identifier("temp"))),, _:CabsLoc))  
                                    ))),, _:CabsLoc))  ))),, 
                                    'BlockStatement('Block(15,, 'list(.List),, 'list(ListItem('CodeLoc('Nop(.KList),, _:CabsLoc))  ))))
                     ,, _:CabsLoc))
                     ListItem('CodeLoc('Computation('_:=_('Identifier("y"),, '_._('*_('Identifier("y")),, 'Identifier("next")))),, _:CabsLoc))
                   ))),, _:CabsLoc))  ))))
          =>
            .K
          ...</k>
          <initializing> 0 </initializing>
          <duration> auto(0) </duration>
//        <final-computation> ... </final-computation>
          <thread-local>...
            <control>
              <control-details>
                <block-stack> _:List </block-stack>
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
                  <nesting-depth> 2 </nesting-depth>
                  <local-addresses> SetItem(AY:Int @ auto(0)) </local-addresses>
                  <local-vars> ListItem(Identifier("y")) </local-vars>
                  <types>
                    Identifier("x")                         |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))
                    Identifier("y")                         |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))
                    Identifier("change")                    |-> t(.Set, int)
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
                  <formatting-wrapper> .Bag </formatting-wrapper>
                  <compound-lit-map> .Map </compound-lit-map>
                  <env>
                    Identifier("x")                         |-> AX:Int @ auto(0)
                    Identifier("y")                         |-> AY:Int @ auto(0)
                    Identifier("change")                    |-> AC:Int @ auto(0)
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
                  <block-history> ListItem(12) ListItem(11) ListItem(6) </block-history>
                </local>
              </control-details>
              <curr-program-loc> _:CabsLoc => ?_:CabsLoc </curr-program-loc>
              <curr-function-params> ListItem(Identifier("x")) </curr-function-params>
              <curr-function> Identifier("bubble_sort") </curr-function>
              <curr-tu> "list.c" </curr-tu>
            </control>
            <call-stack> _:List </call-stack>
          ...</thread-local>
        </thread>
      </threads>
    //<effective-types> _:Map </effective-types>
    //<rand-nat> _:KItem </rand-nat>
    //<next-thread-id> _:KItem </next-thread-id>
    //<thread-info>
    //  <thread-status> _:Map </thread-status>
    //  <mutexes> _:Map </mutexes>
    //  <glocks> _:List </glocks>
    //</thread-info>
    </exec>
    <input> _:List </input>
    <output> _:List </output>
    <result-value> _:K </result-value>
    <options> _:Set </options>
  </T>
//
requires PX =/=K NullPointer
 andBool ( sorted(LXY:List ListItem(ii(V3,V2,V1,V0))) orBool ii(C3,C2,C1,C0) =/=K 0 )
 andBool ( ii(C3,C2,C1,C0) ==K 0 orBool ii(C3,C2,C1,C0) ==K 1 ) // truth value
 andBool min(t(.Set, int)) <=Int ii(V3,V2,V1,V0) andBool ii(V3,V2,V1,V0) <=Int max(t(.Set, int)) // overflow
//
ensures  ( sorted(?LX2:List) orBool ii(?NC3,?NC2,?NC1,?NC0) =/=K 0 )
 andBool list2set(LXY:List) U { ii(V3,V2,V1,V0) } U list2set(LYNext:List) ==K list2set(?LX2:List)
 andBool ( ii(?NC3,?NC2,?NC1,?NC0) ==K 0 orBool ii(?NC3,?NC2,?NC1,?NC0) ==K 1 ) // truth value


rule [func-bubble-sort]:
//<global>
    <mem>...  
      MEM:Map
    (
      lseg( LP1:CanonicalSymLoc, NullPointer)( L1:List)
    =>
      lseg(?LP2:CanonicalSymLoc, NullPointer)(?L2:List)
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
                tv(loc(1 @ static("list.c"), 0), // bubble_sort
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
ensures  sorted(?L2)
 andBool list2set(L1) ==K list2set(?L2)

endmodule
