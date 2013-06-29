module C-DECLARATION-RESOLUTION
     imports C-DECLARATION-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-COMPAT-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-SYMLOC-SYNTAX
     
     syntax K ::= "canonicalizeTranslationUnitVariables"
     rule [unpack-TranslationUnit]:
          <k> TranslationUnit(TUName:String, Strings:K, K:K, P:String) 
               => preDeclareStrings(Strings:K)
               ~> klistToK(eraseKLabel('StmtCons, K:K))
          ...</k>
          <currTU> _ => TUName:String </currTU>
          <declarationOrder> 
               DeclOrder:Map => DeclOrder:Map[ListToK(.List) / TUName:String] 
          </declarationOrder>
          <internalLocations>
               ExtLoc:Map => ExtLoc:Map[map(.) / TUName:String]
          </internalLocations>
          <br/>
          <funTUs> Funs:Map => Funs:Map[map(.) / TUName:String] </funTUs>
          <translationUnits>...
               . => BagItem(TUName:String)
          ...</translationUnits>
          <preLinkage>
               Lnk:Map => Lnk:Map[map(.) / TUName:String]
          </preLinkage>
          <preTypes>
               Types:Map => Types:Map[map(.) / TUName:String]
          </preTypes>
          <br/>
          <internalDefinitions>
               Def:Map => Def:Map[map(.) / TUName:String]
          </internalDefinitions>
          <genv> Env:Map => Env:Map[map(.) / TUName:String] </genv>
          <gtypes> Gtypes:Map => Gtypes:Map[map(.) / TUName:String]</gtypes>
          <programText> M:Map => M:Map[P:String / TUName:String] </programText>
          when notBool $hasMapping(Env:Map, TUName:String)
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
               BagItem(leftover(Tu:K, X:Id, T:KResult)) => .Bag
          ...</leftoverExterns>
          [structural]
     rule <k> resolveLeftovers ...</k>
          <externalLocations> Locs:Map </externalLocations>
          <leftoverExterns>...
               BagItem(leftover(_, X:Id, _)) => .Bag
          ...</leftoverExterns>
          when notBool $hasMapping(Locs:Map, X:Id)
          [structural]
     
     rule <k> resolveLeftovers => .K ...</k>
          <leftoverExterns> .Bag </leftoverExterns>
          [structural]
               
     syntax K ::= "resolveInternal" "(" Id "," K "," K ")"
     syntax K ::= "resolveExternal" "(" Id "," K "," Bag "," K ")"
     syntax K ::= "resolveExternal'" "(" Id "," K "," Bag "," K "," SymLoc "," K ")"
          [strict(6)]
     
     // name, type, context, where defined
     syntax K ::= "recordFunTUInfo" "(" K "," Type "," K "," K ")"
     rule <k> recordFunTUInfo(X:Id, T:KResult, Tu:K, DefTu:K) => .K ...</k>
          <funTUs>...
               Tu:K |-> map((Funs:Map => Funs:Map[DefTu:K / X:Id]))
          ...</funTUs>
          when isFunctionType(T:KResult)
          [structural] 
     rule <k> recordFunTUInfo(_, T:KResult, _, _) => .K ...</k>
          when notBool isFunctionType(T:KResult)
          [structural] 
     
     // fixme
     // should be adding to env after figuring initializer
     // should be changing env to be correct env before figuring initializer
     syntax K ::= "resolveInternal'" "(" Id "," K "," K "," K ")" [strict(4)] 
     rule <k> 
               resolveInternal(X:Id, Tu:K, 
                    declarationObject(T:KResult, Tu:K, K:K))
               => resolveInternal'(X:Id, Tu:K, 
                    declarationObject(T:KResult, Tu:K, K:K), 
                    figureInit(X:Id, T:KResult, K:K))
          ...</k>
          <currTU> _ => Tu:K </currTU>
          [structural] 
     rule <k> 
               resolveInternal'(X:Id, Tu:K, 
                    declarationObject(_, Tu:K, _), 
                    initValue(X:Id, T:KResult, K:K))
               => allocateType(Loc, T:KResult)
                    ~> addToEnv(X:Id, Loc)
                    ~> giveType(X:Id, T:KResult)
                    ~> initialize(X:Id, T:KResult, K:K)
                    ~> recordFunTUInfo(X:Id, T:KResult, Tu:K, Tu:K)
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <currTU> _ => Tu:K </currTU>
          [structural] 
               
     rule <k> 
               resolveExternal(X:Id, Tu:K, Units:Bag, 
                    declarationObject(T:KResult, DefTu:K, K:K))
               => resolveExternal'(X:Id, Tu:K, Units:Bag,
                    declarationObject(T:KResult, DefTu:K, K:K), Loc, 
                    figureInit(X:Id, T:KResult, K:K))
          ...</k>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          [structural] 
     rule <k> 
               ( .K
               => addToEnv(X:Id, Loc)
                    ~> giveType(X:Id, T:KResult)
                    ~> recordFunTUInfo(X:Id, T:KResult, Tu':K, DefTu:K)
               ) ~> resolveExternal'(X:Id, _:K, 
                    ((BagItem(Tu':K) => .) _:Bag),
                    declarationObject(_, DefTu:K, _), Loc:SymLoc, 
                    initValue(X:Id, T:KResult, _:K))
          ...</k>
          <br/>
          <currTU> _ => Tu':K </currTU>
          <preLinkage>...
               Tu':K |-> map((_ (X:Id |-> external => .)))
          ...</preLinkage>
          [structural, large] 
     rule <k> 
               resolveExternal'(X:Id, Tu:K, .Bag,
                    declarationObject(_, DefTu:K, _), Loc:SymLoc,
                    initValue(X:Id, T:KResult, K:K))
               => allocateType(Loc, T:KResult)
                    ~> addToEnv(X:Id, Loc)
                    ~> giveType(X:Id, T:KResult)
                    ~> initialize(X:Id, T:KResult, K:K)
                    ~> recordFunTUInfo(X:Id, T:KResult, Tu:K, DefTu:K)
          ...</k>
          <currTU> _ => Tu:K </currTU>
          <externalLocations>
               Locs:Map => Locs:Map[Loc / X:Id]
          </externalLocations>
          when notBool $hasMapping(Locs:Map, X:Id)
          [structural] 
     rule <k>
               resolveExternal'(X:Id, _,
                    ((BagItem(Tu:K) => .) _:Bag), _, _, _)
          ...</k>
          <preLinkage>... Tu:K |-> map(M:Map) ...</preLinkage>
          when notBool $hasMapping(M:Map, X:Id)
          [structural] 
     rule [resolveExternal-internal]:
          <k>
               resolveExternal'(X:Id, _,
                    ((BagItem(Tu:K) => .) _:Bag), _, _, _)
          ...</k>
          <preLinkage>... Tu:K |-> map((_ X:Id |-> internal)) ...</preLinkage>
          [structural] 
     
     rule <k> (. => resolveInternal(X:Id, Tu:K, K:K)) ~> resolve(Tu:K) ...</k>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> internal => .Map)))
          ...</preLinkage>
          <internalDefinitions>...
               Tu:K |-> map((_ (X:Id |-> K:K => .Map)))
          ...</internalDefinitions>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .List) _)
          ...</declarationOrder>
          [structural] 
          
     // static variable without an initializer
     rule <k> 
               (. => resolveInternal(X:Id, Tu:K, 
                    declarationObject(unqualifyType(T:KResult), Tu:K, 
                    initializer(zero(X:Id))))) ~> resolve(Tu:K)
          ...</k>
          <br/>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> internal => .Map)))
          ...</preLinkage>
          <internalDefinitions>...
               Tu:K |-> map(Defs:Map)
          ...</internalDefinitions>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .List) _)
          ...</declarationOrder>
          <preTypes>...
               Tu:K |-> map((_ (X:Id |-> T:KResult => .Map)))
          ...</preTypes>
          when notBool $hasMapping(Defs:Map, X:Id)
          [structural, large] 
          
     rule <k>
               (. => resolveExternal(X:Id, Tu:K, Units:Bag, K:K)) 
               ~> resolve(Tu:K)
          ...</k>
          <br/>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> external => .Map)))
          ...</preLinkage>
          <externalDefinitions>
               ExtDefs:Map (X:Id |-> K:K => .Map)
          </externalDefinitions>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .List) _)
          ...</declarationOrder>
          <translationUnits> Units:Bag </translationUnits>
          when notBool $hasMapping(ExtDefs:Map, X:Id)
          [structural, large] 

     
     // fixme this means we've declared it twice (like a prototype maybe_), but
     // already handled it.  happening with getc in clib.c
     rule <k> resolve(Tu:K) ...</k>
          <preLinkage>... Tu:K |-> map(Lnk:Map) ...</preLinkage>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <externalDefinitions> ExtDefs:Map </externalDefinitions>
          <internalDefinitions> IntDefs:Map </internalDefinitions>
          when notBool ($hasMapping(Lnk:Map, X:Id))
               andBool (notBool $hasMapping(ExtDefs:Map, X:Id))
               andBool (notBool $hasMapping(IntDefs:Map, X:Id))
          [structural] 
     
     // function prototypes
     rule <k> 
               (. => 
                    giveType(X:Id, T:KResult)
                    // fixme fake Tu
                    ~> recordFunTUInfo(X:Id, T:KResult, Tu:K, Tu:K)
               )
               ~> resolve(Tu:K) 
          ...</k>
          <br/>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> external => .)))
          ...</preLinkage>
          <preTypes>...
               Tu:K |-> map((_ X:Id |-> t(_, prototype(T:KResult))))
          ...</preTypes>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <br/>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <currTU> _ => Tu:K </currTU>
          when isFunctionType(T:KResult)
               andBool (notBool $hasMapping(Defs:Map, X:Id))
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
               => allocateType(Loc, unqualifyType(T:KResult))
                    ~> addToEnv(X:Id, Loc)
                    ~> giveType(X:Id, unqualifyType(T:KResult))
                    ~> zero(X:Id)
               ) ~> resolve(Tu:K)
          ...</k>
          <br/>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> external => .)))
          ...</preLinkage>
          <preTypes>...
               Tu:K |-> map((_ X:Id |-> T:KResult))
          ...</preTypes>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <br/>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <currTU> _ => Tu:K </currTU>
          <nextSharedLoc> Loc:SymLoc => linc(Loc) </nextSharedLoc>
          <externalLocations>
               Locs:Map => Locs:Map[Loc / X:Id]
          </externalLocations>
          when notBool $hasMapping(Locs:Map, X:Id)
               andBool (notBool isFunctionType(T:KResult))
               andBool (notBool isIncompleteType(T:KResult))
               andBool (notBool isExternType(T:KResult))
               andBool (notBool $hasMapping(Defs:Map, X:Id))
          [structural, large] 
     syntax K ::= "leftover" "(" K "," K "," K ")"
     rule [resolve-extern-object-nomapping]:
          <k> resolve(Tu:K) ...</k>
          <preLinkage>...
               Tu:K |-> map((_ (X:Id |-> external => .)))
          ...</preLinkage>
          <preTypes>...
               Tu:K |-> map((_ X:Id |-> T:KResult))
          ...</preTypes>
          <declarationOrder>...
               Tu:K |-> ListToK((ListItem(X:Id) => .) _)
          ...</declarationOrder>
          <externalDefinitions> Defs:Map </externalDefinitions>
          <leftoverExterns>...
               .Bag => BagItem(leftover(Tu:K, X:Id, T:KResult))
          ...</leftoverExterns>
          when notBool isFunctionType(T:KResult)
               andBool isExternType(T:KResult)
               andBool notBool $hasMapping(Defs:Map, X:Id)
          [structural] 
          
     rule <k> resolve(Tu:K) => . ...</k>
          <preLinkage>... Tu:K |-> map(.) ...</preLinkage>
          <internalDefinitions>... Tu:K |-> map(.) ...</internalDefinitions>
          <declarationOrder>... Tu:K |-> ListToK(.List) ...</declarationOrder>
          [structural] 
                    
     // need to worry about things that don't have definitions that may
     // override externs
     // want to make it so env is always correct local env, so need to have a
     // set of global envs, one for each tu
     
     rule [initialize-function]:
          <k> 
               initFunction(tv(Loc:SymLoc, 
                    t(_, pointerType(T:KResult))), Fun:KResult) 
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

