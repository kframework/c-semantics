module C-DECLARATION-RESOLUTION
     imports C-DECLARATION-GENERAL-SYNTAX
     imports C-DECLARATION-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports COMPAT-SYNTAX
     
     syntax K ::= "canonicalizeTranslationUnitVariables"
     rule [unpack-TranslationUnit]:
          <k> 
               TranslationUnit(TUName:String, Strings:K, K:K, P:String) 
               => preDeclareStrings(Strings)
                    ~> klistToK(eraseKLabel('StmtCons, K))
          ...</k>
          <currTU> _ => TUName </currTU>
          <declarationOrder> 
               DeclOrder:Map => DeclOrder:Map[ListToK(.List) / TUName] 
          </declarationOrder>
          <internalLocations>
               ExtLoc:Map => ExtLoc:Map[map(.) / TUName]
          </internalLocations>
          <funTUs> Funs:Map => Funs:Map[map(.) / TUName] </funTUs>
          <translationUnits>...
               . => BagItem(TUName)
          ...</translationUnits>
          <preLinkage>
               Lnk:Map => Lnk:Map[map(.) / TUName]
          </preLinkage>
          <preTypes>
               Types:Map => Types:Map[map(.) / TUName]
          </preTypes>
          <internalDefinitions>
               Def:Map => Def:Map[map(.) / TUName]
          </internalDefinitions>
          <genv> Env:Map => Env:Map[map(.) / TUName] </genv>
          <gtypes> Gtypes:Map => Gtypes:Map[map(.) / TUName]</gtypes>
          <programText> M:Map => M:Map[P / TUName] </programText>
          when notBool $hasMapping(Env, TUName)
          [structural, large]
          
     syntax K ::= "preDeclareStrings" "(" K ")"
     
     rule preDeclareStrings(klist((K:K,, L:KList)))
          => K ~> discard ~> preDeclareStrings(klist(L))
          [structural]
     rule preDeclareStrings(klist(.KList)) => .
          [structural]
     
     syntax K ::= "resolve" "(" K ")"
     rule <k> (. => resolve(Tu:K)) ~> resolveReferences ...</k>
          <translationUnits>... BagItem(Tu:K) => .Bag ...</translationUnits>
          [structural] 
          
     syntax K ::= "resolveLeftovers"
     rule <k> resolveReferences => resolveLeftovers ...</k>
          <translationUnits> .Bag </translationUnits>
          [structural] 
          
     rule <k> (.K =>
               addToEnv(X, Loc)
               ~> giveType(X, unqualifyType(T))
               ) ~> resolveLeftovers 
          ...</k>
          <currTU> _ => Tu </currTU>
          <externalLocations>... X |-> Loc:SymLoc ...</externalLocations>
          <leftoverExterns>...
               BagItem(leftover(Tu:K, X:Id, T:Type)) => .Bag
          ...</leftoverExterns>
          [structural]
     rule <k> resolveLeftovers ...</k>
          <externalLocations> Locs:Map </externalLocations>
          <leftoverExterns>...
               BagItem(leftover(_, X:Id, _)) => .Bag
          ...</leftoverExterns>
          when notBool $hasMapping(Locs, X)
          [structural]
     
     rule <k> resolveLeftovers => .K ...</k>
          <leftoverExterns> .Bag </leftoverExterns>
          [structural]
               
     syntax K ::= "resolveInternal" "(" Id "," K "," K ")"
     syntax K ::= "resolveExternal" "(" Id "," K "," Bag "," K ")"
     syntax K ::= "resolveExternal'" "(" Id "," K "," Bag "," K "," SymLoc "," K ")"
          [strict(6)]
     
     // name, type, context, where defined
     syntax K ::= recordFunTUInfo(K, Type, K, K)
     rule <k> recordFunTUInfo(X:Id, T:Type, Tu:K, DefTu:K) => . ...</k>
          <funTUs>...
               Tu:K |-> map((Funs:Map => Funs:Map[DefTu:K / X:Id]))
          ...</funTUs>
          when isFunctionType(T) 
               andBool X =/=K Identifier("main")
          [structural] 
     rule <k> 
               recordFunTUInfo(Identifier("main"), T:Type, Tu:K, DefTu:K)
               => . 
          ...</k>
          <funTUs>...
               Tu:K |-> map((Funs:Map => Funs:Map[DefTu:K / Identifier("main")]))
          ...</funTUs>
          <mainTU> _ => DefTu </mainTU>
          when isFunctionType(T) 
          [structural] 
     rule <k> recordFunTUInfo(_, T:Type, _, _) => . ...</k>
          when notBool isFunctionType(T)
          [structural] 
     
     // fixme
     // should be adding to env after figuring initializer
     // should be changing env to be correct env before figuring initializer
     syntax K ::= "resolveInternal'" "(" Id "," K "," K "," K ")" [strict(4)] 
     rule <k> 
               resolveInternal(X:Id, Tu:K, 
                    declarationObject(T:Type, Tu:K, K:K))
               => resolveInternal'(X, Tu, 
                    declarationObject(T, Tu, K), 
                    figureInit(X, T, K))
          ...</k>
          <currTU> _ => Tu </currTU>
          [structural] 
     rule <k> 
               resolveInternal'(X:Id, Tu:K, 
                    declarationObject(_, Tu:K, _), 
                    initValue(X:Id, T:Type, K:K))
               => allocateType(Loc, T)
                    ~> addToEnv(X, Loc)
                    ~> giveType(X, T)
                    ~> initialize(X, T, K)
                    ~> recordFunTUInfo(X, T, Tu, Tu)
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <currTU> _ => Tu </currTU>
          [structural] 
               
     rule <k> 
               resolveExternal(X:Id, Tu:K, Units:Bag, 
                    declarationObject(T:Type, DefTu:K, K:K))
               => resolveExternal'(X, Tu, Units,
                    declarationObject(T, DefTu, K), Loc, 
                    figureInit(X, T, K))
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          [structural] 
     rule <k> 
               ( .K
               => addToEnv(X, Loc)
                    ~> giveType(X, T)
                    ~> recordFunTUInfo(X, T, Tu', DefTu)
               ) ~> resolveExternal'(X:Id, _:K, 
                    ((BagItem(Tu':K) => .) _:Bag),
                    declarationObject(_, DefTu:K, _), Loc:SymLoc, 
                    initValue(X:Id, T:Type, _:K))
          ...</k>
          <currTU> _ => Tu' </currTU>
          <preLinkage>...
               Tu' |-> map((_ (X |-> external => .)))
          ...</preLinkage>
          [structural, large] 
     rule <k> 
               resolveExternal'(X:Id, Tu:K, .Bag,
                    declarationObject(_, DefTu:K, _), Loc:SymLoc,
                    initValue(X:Id, T:Type, K:K))
               => allocateType(Loc, T)
                    ~> addToEnv(X, Loc)
                    ~> giveType(X, T)
                    ~> initialize(X, T, K)
                    ~> recordFunTUInfo(X, T, Tu, DefTu)
          ...</k>
          <currTU> _ => Tu </currTU>
          <externalLocations>
               Locs:Map => Locs:Map[Loc / X]
          </externalLocations>
          when notBool $hasMapping(Locs, X)
          [structural] 
     rule <k>
               resolveExternal'(X:Id, _,
                    ((BagItem(Tu:K) => .) _:Bag), _, _, _)
          ...</k>
          <preLinkage>... Tu |-> map(M:Map) ...</preLinkage>
          when notBool $hasMapping(M, X)
          [structural] 
     rule [resolveExternal-internal]:
          <k>
               resolveExternal'(X:Id, _,
                    ((BagItem(Tu:K) => .) _:Bag), _, _, _)
          ...</k>
          <preLinkage>... Tu |-> map((_ X:Id |-> internal)) ...</preLinkage>
          [structural] 
     
     rule <k> (. => resolveInternal(X, Tu, K)) ~> resolve(Tu:K) ...</k>
          <preLinkage>...
               Tu |-> map((_ (X:Id |-> internal => .Map)))
          ...</preLinkage>
          <internalDefinitions>...
               Tu |-> map((_ (X:Id |-> K:K => .Map)))
          ...</internalDefinitions>
          <declarationOrder>...
               Tu |-> ListToK((ListItem(X:Id) => .List) _)
          ...</declarationOrder>
          [structural] 
          
     // static variable without an initializer
     rule <k> 
               (. => resolveInternal(X, Tu, 
                    declarationObject(unqualifyType(T), Tu, 
                    initializer(zero(X))))) ~> resolve(Tu:K)
          ...</k>
          <preLinkage>...
               Tu |-> map((_ (X:Id |-> internal => .Map)))
          ...</preLinkage>
          <internalDefinitions>...
               Tu |-> map(Defs:Map)
          ...</internalDefinitions>
          <declarationOrder>...
               Tu |-> ListToK((ListItem(X:Id) => .List) _)
          ...</declarationOrder>
          <preTypes>...
               Tu |-> map((_ (X:Id |-> T:Type => .Map)))
          ...</preTypes>
          when notBool $hasMapping(Defs, X)
          [structural, large] 
          
     rule <k>
               (. => resolveExternal(X, Tu, Units, K)) 
               ~> resolve(Tu:K)
          ...</k>
          <br/>
          <preLinkage>...
               Tu |-> map((_ (X:Id |-> external => .Map)))
          ...</preLinkage>
          <externalDefinitions>
               ExtDefs:Map (X:Id |-> K:K => .Map)
          </externalDefinitions>
          <declarationOrder>...
               Tu |-> ListToK((ListItem(X:Id) => .List) _)
          ...</declarationOrder>
          <translationUnits> Units:Bag </translationUnits>
          when notBool $hasMapping(ExtDefs, X)
          [structural, large] 

     
     // fixme this means we've declared it twice (like a prototype maybe_), but
     // already handled it.  happening with getc in clib.c
     rule <k> resolve(Tu:K) ...</k>
          <preLinkage>... Tu |-> map(Lnk:Map) ...</preLinkage>
          <declarationOrder>...
               Tu |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <externalDefinitions> ExtDefs:Map </externalDefinitions>
          <internalDefinitions> IntDefs:Map </internalDefinitions>
          when notBool ($hasMapping(Lnk, X))
               andBool (notBool $hasMapping(ExtDefs, X))
               andBool (notBool $hasMapping(IntDefs, X))
          [structural] 
     
     // function prototypes
     rule <k> 
               (. => 
                    giveType(X, T)
                    // fixme fake Tu
                    ~> recordFunTUInfo(X, T, Tu, Tu)
               )
               ~> resolve(Tu:K) 
          ...</k>
          <preLinkage>...
               Tu |-> map((_ (X:Id |-> external => .)))
          ...</preLinkage>
          <preTypes>...
               Tu |-> map((_ X:Id |-> t(_, prototype(T:Type))))
          ...</preTypes>
          <declarationOrder>...
               Tu |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <br/>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <currTU> _ => Tu </currTU>
          when isFunctionType(T)
               andBool (notBool $hasMapping(Defs, X))
          [structural, large] 
          
     // c1x 6.9.2:2 A declaration of an identifier for an object that has file
     // scope without an initializer, and without a storage-class specifier or
     // with the storage-class specifier static, constitutes a tentative
     // definition. If a translation unit contains one or more tentative
     // definitions for an identifier, and the translation unit contains no
     // external definition for that identifier, then the behavior is exactly
     // as if the translation unit contains a file scope declaration of that
     // identifier, with the composite type as of the end of the translation
     // unit, with an initializer equal to 0
     rule <k> 
               (. 
               => allocateType(Loc, unqualifyType(T))
                    ~> addToEnv(X, Loc)
                    ~> giveType(X, unqualifyType(T))
                    ~> zero(X)
               ) ~> resolve(Tu:K)
          ...</k>
          <br/>
          <preLinkage>...
               Tu |-> map((_ (X:Id |-> external => .)))
          ...</preLinkage>
          <preTypes>...
               Tu |-> map((_ X:Id |-> T:Type))
          ...</preTypes>
          <declarationOrder>...
               Tu |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <currTU> _ => Tu </currTU>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <externalLocations>
               Locs:Map => Locs:Map[Loc / X]
          </externalLocations>
          when notBool $hasMapping(Locs, X)
               andBool (notBool isFunctionType(T))
               andBool (notBool isIncompleteType(T))
               andBool (notBool isExternType(T))
               andBool (notBool $hasMapping(Defs, X))
          [structural, large] 
     syntax K ::= "leftover" "(" K "," Id "," Type ")"
     rule [resolve-extern-object-nomapping]:
          <k> resolve(Tu:K) ...</k>
          <preLinkage>...
               Tu |-> map((_ (X:Id |-> external => .)))
          ...</preLinkage>
          <preTypes>...
               Tu |-> map((_ X:Id |-> T:Type))
          ...</preTypes>
          <declarationOrder>...
               Tu |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <leftoverExterns>...
               .Bag => BagItem(leftover(Tu, X, T))
          ...</leftoverExterns>
          when notBool isFunctionType(T)
               andBool isExternType(T)
               andBool notBool $hasMapping(Defs, X)
          [structural] 
          
     rule <k> resolve(Tu:K) => . ...</k>
          <preLinkage>... Tu |-> map(.) ...</preLinkage>
          <internalDefinitions>... Tu |-> map(.) ...</internalDefinitions>
          <declarationOrder>... Tu |-> ListToK(.List) ...</declarationOrder>
          [structural] 
                    
     // need to worry about things that don't have definitions that may
     // override externs
     // want to make it so env is always correct local env, so need to have a
     // set of global envs, one for each tu
     
     rule [initialize-function]:
          <k> 
               initFunction(tv(Loc:SymLoc, 
                    t(_, pointerType(T:Type))), Fun:KResult) 
               => .K
          ...</k>
          <functions> M:Map => M:Map[Fun / Loc] </functions>
          when isFunctionType(T)
               andBool notBool $hasMapping(M, Loc)
          [structural]
          
     rule <k> readFunction(Loc:SymLoc) => Fun  ...</k>
          <functions>... Loc |-> Fun:KResult ...</functions>
          [structural]
     
endmodule

