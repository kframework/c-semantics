require "c-verifier.k"

module QUICKSORT-SPEC
imports C-VERIFIER

rule [append-loop-inv]:
  <global>
    <mem>...  
      MEM:Map
    '_Map_(
      AY @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(_:CanonicalSymLoc, 0, 0), 8)
        1 |-> piece(subObject(_:CanonicalSymLoc, 1, 1), 8)
        2 |-> piece(subObject(_:CanonicalSymLoc, 2, 2), 8)
        3 |-> piece(subObject(_:CanonicalSymLoc, 3, 3), 8), .Map)
    ,,AX @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(PX:CanonicalSymLoc, 0, 0), 8)
        1 |-> piece(subObject(PX:CanonicalSymLoc, 1, 1), 8)
        2 |-> piece(subObject(PX:CanonicalSymLoc, 2, 2), 8)
        3 |-> piece(subObject(PX:CanonicalSymLoc, 3, 3), 8), .Map)
    ,,AP @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(loc((PP:Int => ?NPP:Int) @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 0, 0), 8)
        1 |-> piece(subObject(loc((PP:Int => ?NPP:Int) @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 1, 1), 8)
        2 |-> piece(subObject(loc((PP:Int => ?NPP:Int) @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 2, 2), 8)
        3 |-> piece(subObject(loc((PP:Int => ?NPP:Int) @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 3, 3), 8), .Map)
    )
    (
      // lseg(x,p)
      lseg(PX:CanonicalSymLoc,
           loc(PP:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))))(LXP:List)
      // lseg(p,null)
      lseg(loc(PP:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))),
           NullPointer)(LP:List)
    =>
      // lseg(x,?np)
      lseg(PX:CanonicalSymLoc,
           loc(?NPP:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))))(?NLXP:List)
      // ?np->null
      ?NPP:Int @ alloc |-> object(t(.Set, no-type), 8,
        0 |-> piece(?NVP0:Int, 8) 
        1 |-> piece(?NVP1:Int, 8) 
        2 |-> piece(?NVP2:Int, 8) 
        3 |-> piece(?NVP3:Int, 8) 
        4 |-> piece(subObject(NullPointer, 0, 0), 8)
        5 |-> piece(subObject(NullPointer, 1, 1), 8)
        6 |-> piece(subObject(NullPointer, 2, 2), 8)
        7 |-> piece(subObject(NullPointer, 3, 3), 8)
       ,0 |-> t(.Set, int)
        4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
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
            'While('_!=_('_._('*_('Identifier("p")),, 'Identifier("next")),, 'Cast('Specifier('list(ListItem('Void(.KList))  )),, 'PointerType('Specifier('list(.List)),, 'JustBase(.KList)),, 'tv(0,, 't(SetItem(IntegerConstant),, 'int(.KList))))),, 
                   'BlockStatement('Block(70,, 'list(.List),, 'list(ListItem('CodeLoc('BlockStatement('Block(71,, 'list(.List),, 'list(
                        ListItem('CodeLoc('Computation('_:=_('Identifier("p"),, '_._('*_('Identifier("p")),, 'Identifier("next")))),, _:CabsLoc))  
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
                  '_Map_(
                    Identifier("x")                         |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))
                  ,,Identifier("y")                         |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))
                  ,,Identifier("p")                         |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))
                    //
                  ,,Identifier("reverse")                   |-> t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))))) 
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
                  <local-addresses> SetItem(AX:Int @ auto(0)) SetItem(AY:Int @ auto(0)) SetItem(AP:Int @ auto(0)) </local-addresses>
                  <env>
                  '_Map_(
                    Identifier("x")                         |-> AX:Int @ auto(0)
                  ,,Identifier("y")                         |-> AY:Int @ auto(0)
                  ,,Identifier("p")                         |-> AP:Int @ auto(0)
                    //
                  ,,Identifier("reverse")                   |-> 0 @ static("list.c") 
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
                  <block-history> ListItem(66) </block-history>
                </local>
              </control-details>
              <curr-program-loc> _:CabsLoc => ?_:CabsLoc </curr-program-loc>
              <curr-function-params> ListItem(Identifier("x")) ListItem(Identifier("y")) </curr-function-params>
              <curr-function> Identifier("append") </curr-function>
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
ensures  (LXP:List LP:List) ==K (?NLXP:List ListItem(ii(?NVP3,?NVP2,?NVP1,?NVP0)))
 andBool min(t(.Set, int)) <=Int ii(?NVP3,?NVP2,?NVP1,?NVP0) andBool ii(?NVP3,?NVP2,?NVP1,?NVP0) <=Int max(t(.Set, int)) // overflow


rule [func-append]:
//<global>
    <mem>...  
      MEM:Map
    (
      lseg( PX:CanonicalSymLoc, NullPointer)(LX:List)
      lseg( PY:CanonicalSymLoc, NullPointer)(LY:List)
    =>
      lseg(?NP:CanonicalSymLoc, NullPointer)(LX:List LY:List)
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
                tv(loc(4 @ static("list.c"), 0), // append
                    t(.Set, pointerType(t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
                                                                                                                                                  ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))))))),
                rvlist(
                    ListItem(tv(PX:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))))
                    ListItem(tv(PY:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))))))
          =>
            tv(?NP:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
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


rule [loop-inv]:
  <global>
    <mem>...  
      MEM:Map
    '_Map_(
      AP @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(loc(PP:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 0, 0), 8)
        1 |-> piece(subObject(loc(PP:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 1, 1), 8)
        2 |-> piece(subObject(loc(PP:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 2, 2), 8)
        3 |-> piece(subObject(loc(PP:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 8))), 3, 3), 8), .Map)
    ,,AX @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(PX:CanonicalSymLoc => NullPointer, 0, 0), 8)
        1 |-> piece(subObject(PX:CanonicalSymLoc => NullPointer, 1, 1), 8)
        2 |-> piece(subObject(PX:CanonicalSymLoc => NullPointer, 2, 2), 8)
        3 |-> piece(subObject(PX:CanonicalSymLoc => NullPointer, 3, 3), 8), .Map)
    ,,AY @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(PY:CanonicalSymLoc => ?NPY:CanonicalSymLoc, 0, 0), 8)
        1 |-> piece(subObject(PY:CanonicalSymLoc => ?NPY:CanonicalSymLoc, 1, 1), 8)
        2 |-> piece(subObject(PY:CanonicalSymLoc => ?NPY:CanonicalSymLoc, 2, 2), 8)
        3 |-> piece(subObject(PY:CanonicalSymLoc => ?NPY:CanonicalSymLoc, 3, 3), 8), .Map)
    ,,AZ @ auto(0) |-> object(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), 4,
        0 |-> piece(subObject(PZ:CanonicalSymLoc => ?NPZ:CanonicalSymLoc, 0, 0), 8)
        1 |-> piece(subObject(PZ:CanonicalSymLoc => ?NPZ:CanonicalSymLoc, 1, 1), 8)
        2 |-> piece(subObject(PZ:CanonicalSymLoc => ?NPZ:CanonicalSymLoc, 2, 2), 8)
        3 |-> piece(subObject(PZ:CanonicalSymLoc => ?NPZ:CanonicalSymLoc, 3, 3), 8), .Map)
    )
      // p->null
      PP:Int @ alloc |-> object(t(.Set, no-type), 8,
        0 |-> piece(VP0:Int, 8) 
        1 |-> piece(VP1:Int, 8) 
        2 |-> piece(VP2:Int, 8) 
        3 |-> piece(VP3:Int, 8) 
        4 |-> piece(subObject(NullPointer, 0, 0), 8)
        5 |-> piece(subObject(NullPointer, 1, 1), 8)
        6 |-> piece(subObject(NullPointer, 2, 2), 8)
        7 |-> piece(subObject(NullPointer, 3, 3), 8)
       ,0 |-> t(.Set, int)
        4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))))
    (
      lseg(PX:CanonicalSymLoc, NullPointer)(LX:List)
      lseg(PY:CanonicalSymLoc, NullPointer)(LY:List)
      lseg(PZ:CanonicalSymLoc, NullPointer)(LZ:List)
    =>
      lseg(?NPY:CanonicalSymLoc, NullPointer)(?NLY:List)
      lseg(?NPZ:CanonicalSymLoc, NullPointer)(?NLZ:List)
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
                   'BlockStatement('Block(81,, 'list(.List),, 'list(ListItem('CodeLoc('BlockStatement('Block(82,, 'list(.List),, 'list(
                        ListItem('CodeLoc('DeclarationDefinition('InitNameGroup('Specifier('list(ListItem('StructRef('Identifier("listNode")))  )),, 'list(ListItem('InitName('Name('Identifier("t"),, 'PointerType('Specifier('list(.List)),, 'JustBase(.KList))),, 'NoInit(.KList)))  ))),, _:CabsLoc)) 
                        ListItem('CodeLoc('Computation('_:=_('Identifier("t"),, 'Identifier("x"))),, _:CabsLoc)) 
                        ListItem('CodeLoc('Computation('_:=_('Identifier("x"),, '_._('*_('Identifier("x")),, 'Identifier("next")))),, _:CabsLoc)) 
                        ListItem('CodeLoc(
                            'IfThenElse('_<_('_._('*_('Identifier("t")),, 'Identifier("val")),, '_._('*_('Identifier("p")),, 'Identifier("val"))),, 
                                        'BlockStatement('Block(85,, 'list(.List),, 'list(ListItem('CodeLoc('BlockStatement('Block(86,, 'list(.List),, 'list(
                                            ListItem('CodeLoc('Computation('_:=_('_._('*_('Identifier("t")),, 'Identifier("next")),, 'Identifier("y"))),, _:CabsLoc)) 
                                            ListItem('CodeLoc('Computation('_:=_('Identifier("y"),, 'Identifier("t"))),, _:CabsLoc))  ))),, _:CabsLoc))  ))),, 
                                        'BlockStatement('Block(83,, 'list(.List),, 'list(ListItem('CodeLoc('BlockStatement('Block(84,, 'list(.List),, 'list(
                                            ListItem('CodeLoc('Computation('_:=_('_._('*_('Identifier("t")),, 'Identifier("next")),, 'Identifier("z"))),, _:CabsLoc)) 
                                            ListItem('CodeLoc('Computation('_:=_('Identifier("z"),, 'Identifier("t"))),, _:CabsLoc))  ))),, _:CabsLoc))  )))),, _:CabsLoc))  
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
                  '_Map_(
                    Identifier("x")                         |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))
                  ,,Identifier("y")                         |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))
                  ,,Identifier("z")                         |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))
                  ,,Identifier("p")                         |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))
                    //
                  ,,Identifier("reverse")                   |-> t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c"))))), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("listNode"), "list.c")))))))) 
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
                  <local-vars> ListItem(Identifier("p")) ListItem(Identifier("y")) ListItem(Identifier("z")) </local-vars>
                  <local-addresses> SetItem(AX:Int @ auto(0)) SetItem(AY:Int @ auto(0)) SetItem(AZ:Int @ auto(0)) SetItem(AP:Int @ auto(0)) </local-addresses>
                  <env>
                  '_Map_(
                    Identifier("x")                         |-> AX:Int @ auto(0)
                  ,,Identifier("y")                         |-> AY:Int @ auto(0)
                  ,,Identifier("z")                         |-> AZ:Int @ auto(0)
                  ,,Identifier("p")                         |-> AP:Int @ auto(0)
                    //
                  ,,Identifier("reverse")                   |-> 0 @ static("list.c") 
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
                  <block-history> ListItem(73) </block-history>
                </local>
              </control-details>
              <curr-program-loc> _:CabsLoc => ?_:CabsLoc </curr-program-loc>
              <curr-function-params> ListItem(Identifier("x")) </curr-function-params>
              <curr-function> Identifier("quicksort") </curr-function>
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
requires list2set(  LY) <=IntSet { ii(VP3,VP2,VP1,VP0) } andBool { ii(VP3,VP2,VP1,VP0) } <=IntSet list2set(  LZ)
 //
 andBool min(t(.Set, int)) <=Int ii(VP3,VP2,VP1,VP0) andBool ii(VP3,VP2,VP1,VP0) <=Int max(t(.Set, int)) // overflow
//
ensures  list2set(?NLY) <=IntSet { ii(VP3,VP2,VP1,VP0) } andBool { ii(VP3,VP2,VP1,VP0) } <=IntSet list2set(?NLZ)
 andBool list2set(LX) U list2set(LY) U list2set(LZ) ==K list2set(?NLY) U list2set(?NLZ)


rule [func-quick-sort]:
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
                tv(loc(5 @ static("list.c"), 0), // quicksort
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
