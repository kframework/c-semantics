module C-STMT-GOTO
     imports C-CONFIGURATION
     imports BOOL
     imports K-REFLECTION
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-IO-SYNTAX
     imports DELETE-OBJECT-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.8.6.1}{2}}}{
     A \cinline{goto} statement causes an unconditional jump to the statement
     prefixed by the named label in the enclosing function.
     }*/

     //  fixme CONFIRM It seems there are no sequence points for a goto

     /*@ \fromStandard{\source[n1570]{\para{6.2.4}{6}}}{
     For such an object that does not have a variable length array type, its
     lifetime extends from entry into the block with which it is associated
     until execution of that block ends in any way. (Entering an enclosed block
     or calling a function suspends, but does not end, execution of the current
     block.) If the block is entered recursively, a new instance of the object
     is created each time. The initial value of the object is indeterminate. If
     an initialization is specified for the object, it is performed each time
     the declaration or compound literal is reached in the execution of the
     block; otherwise, the value becomes indeterminate each time the
     declaration is reached.
     }*/
/*
     things I have to keep track of:
          in goto map:
               remaining computation
               which variables are allocated on the path
               ...
          in blocks:
               which variables i've allocated so far

     I need to adjust the block stack,

     When we goto, we need to take the variables on the goto path and subtract
     the variables we've already allocated in the real history.  Then we need
     to declare the remaining variables

*/

     /*
          To do the actual goto:
               - Case 1: We are in the same block as the target
                    1. We might be jumping forwards or backwards, across
                    declarations, so we need to figure out which variables
                    should be left alone, allocated but not initialized, or
                    deallocated
                         a. Skip any entries in the frozen decl-stack
                         where the nesting-depth is smaller than our current
                         nesting-depth
                         b. All that remains should be variables in the same
                         block as the target
                         c. As we step through the variables in the frozen
                         decl-stack
                              i. any variables we see that we have already
                              declared stay allocated and keep their old value
                              ii. any variables that are in the
                              decl-stack but have not been declared are
                              variables we must allocate but not initialize
                              iii. any variables that have been declared but
                              are not in the decl-stack need to be
                              deallocated
               - Case 2: We are in a different block than the target
                    1. We need to unwind blocks from the blockstack until we're
                    in at nesting-depth 1 less than the nesting depth of the
                    target
                         a. for each block we pop, we need to unallocate the
                         memory
                         b. once we're at the right place, we enter the block
                         and then proceed similarly to case 1, except all the
                         cases will be to allocate and not initialize

          The variables mentioned above are meant to be those with automatic
          storage duration.  Variables with external or static storage duration
          have their own rules

     */

     rule <k> Goto(Lbl:CId) => gotoUp({G[Lbl]}:>GotoObject) ...</k>
          <curr-scope> blockScope(F::CId, _) </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>...
               F |-> G::Map
          ...</goto-map>
          requires Lbl =/=K funLabel
     rule <k> Goto(funLabel) ~> _ => Blk </k>
          <curr-scope> blockScope(F::CId, _) </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>...
               F |-> (_ funLabel |-> gotoObject(_, Blk:K, _, _))
          ...</goto-map>

     // - as long as there are entries in the actual block history that differ
     // from the target block history, we need to pop
     syntax KItem ::= gotoUp(GotoObject)
     rule <k> (.K => popBlock)
               ~> gotoUp(gotoObject(TargetHistory::List, _, _, _))
          ...</k>
          <block-history>
               ActualHistory:List
          </block-history>
          requires notBool (isSuffixOf(ActualHistory, TargetHistory)
               andBool size(ActualHistory) <=Int size(TargetHistory))
          [structural]
     // once we share a history, we start to push
     rule <k> gotoUp(gotoObject(TargetHistory::List, K:K, LoopStack::List, DeclStack::List))
               => declVariables(filterDecls(BlockNum, Locals getStatics(Locals, Scope, Statics), DeclStack))
               ~> rewindEnv(intersectSet(keys(Env) -Set filterIds(BlockNum, DeclStack), Locals getStatics(keys(Env), Scope, Statics)))
               ~> gotoDown(reverseList(range(TargetHistory, 0, size(ActualHistory))),
                    K,
                    LoopStack,
                    DeclStack)
          ...</k>
          <env> Env:Map </env>
          <block-history>
               (ListItem(BlockNum::Int) ActualHistory'::List) #as ActualHistory::List
          </block-history>
          <local-vars> Locals::Set </local-vars>
          <curr-scope> Scope::Scope </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <local-statics> Statics::Map </local-statics>
          requires isSuffixOf(ActualHistory, TargetHistory)
               andBool size(ActualHistory) <=Int size(TargetHistory)
          [structural]

     syntax KItem ::= gotoDown(List, K, List, List)
     rule (.K => pushBlock(BlockNum) ~> declVariables(filterDecls(BlockNum, .Set, DeclStack)))
          ~> gotoDown((ListItem(BlockNum::Int) => .List) _, _, _, DeclStack::List)
          [structural]
     // - when we're in the same block
     rule <k> gotoDown(.List, K:K, LoopStack::List, _)
               ~> _
               => K
          </k>
          <loop-stack> _ => LoopStack </loop-stack>
          [structural]

     syntax KItem ::= rewindEnv(Set)
     rule <k> (.K => deleteObject(B) ~> revertLocal(X))
               ~> rewindEnv((SetItem(X::CId) => .Set) _)
          ...</k>
          <env>...
               X |-> B::SymBase
          ...</env>
          <renv>...
               B |-> _ => .Map
          ...</renv>
          <local-vars>... SetItem(X) => .Set ...</local-vars>
          <local-addresses>... SetItem(B) => .Set ...</local-addresses>
          requires notBool isCompoundLiteralId(X)
     rule <k> (.K => revertLocal(X))
               ~> rewindEnv((SetItem(X::CId) => .Set) _)
          ...</k>
          <curr-scope> Scope::Scope </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <local-statics> Statics::Map </local-statics>
          requires kpair(X, Scope) in_keys(Statics)
     rule rewindEnv((SetItem(X::CId) => .Set) _)
          requires isCompoundLiteralId(X)
     rule rewindEnv(.Set) => .K

     syntax KItem ::= revertLocal(CId)
     rule <k> revertLocal(X::CId) => .K ...</k>
          <env>... X |-> _ => .Map ...</env>
          <types>... X |-> _ => .Map ...</types>
          <block-stack>
               ListItem(<block-control>...
                    <env> Env::Map </env>
               ...</block-control>)
          ...</block-stack>
          requires notBool X in_keys(Env)
     rule <k> revertLocal(X::CId) => .K ...</k>
          <env>... X |-> _ => .Map ...</env>
          <types>... X |-> _ => .Map ...</types>
          <block-stack> .List </block-stack>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> Env::Map </genv>
          requires notBool X in_keys(Env)
     rule <k> revertLocal(X::CId) => .K ...</k>
          <env>... X |-> (_ => B) ...</env>
          <types>... X |-> (_ => T) ...</types>
          <block-stack>
               ListItem(<block-control>...
                    <env>...
                         X |-> B::SymBase
                    ...</env>
                    <types>...
                         X |-> T::Type
                    ...</types>
               ...</block-control>)
          ...</block-stack>
     rule <k> revertLocal(X::CId) => .K ...</k>
          <env>... X |-> (_ => B) ...</env>
          <types>... X |-> (_ => T) ...</types>
          <block-stack> .List </block-stack>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv>...
               X |-> B::SymBase
          ...</genv>
          <gtypes>...
               X |-> T::Type
          ...</gtypes>

     syntax Set ::= filterIds(Int, List) [function]
     rule filterIds(B::Int, ListItem(frozenDeclaration(B, Decl:K)) Ds::List)
          => SetItem(getIdOfDecl(Decl)) filterIds(B, Ds)
     rule filterIds(_, (ListItem(_) => .List) _) [owise]
     rule filterIds(_, .List) => .Set

     syntax Set ::= filterDecls(Int, Set, List) [function]
     rule filterDecls(B::Int, Locals::Set, ListItem(frozenDeclaration(B, Decl:K)) Ds::List)
          => SetItem(Decl) filterDecls(B, Locals, Ds)
          requires notBool (getIdOfDecl(Decl) in Locals)
     rule filterDecls(_, _, (ListItem(_) => .List) _) [owise]
     rule filterDecls(_, _, .List) => .Set

     syntax CId ::= getIdOfDecl(K) [function]
     rule getIdOfDecl(declareInternalVariable(X:CId, _, _)) => X
     rule getIdOfDecl(typedef(X:CId, _)) => X

     syntax KItem ::= declVariables(Set)
     rule <k> (.K => Decl ~> enableInits)
               ~> declVariables((SetItem(Decl:KItem) => .Set) _)
          ...</k>
          <should-init> _ => false </should-init>
          [structural]
     rule declVariables(.Set) => .K
          [structural]

     syntax KItem ::= "enableInits"
     rule <k> enableInits => .K ...</k>
          <should-init> _ => true </should-init>
          [structural]

     // isSuffixOf(A, B) => true iff list A is a suffix of B
     syntax Bool ::= isSuffixOf(List, List) [function]
     rule isSuffixOf(.List, _) => true
     rule isSuffixOf(L:List ListItem(K:KItem), L':List ListItem(K))
          => isSuffixOf(L, L')
     rule isSuffixOf(_, _) => false [owise]

     syntax Set ::= getStatics(Set, Scope, Map) [function]
     rule getStatics(SetItem(X::CId) Ids::Set, Scope::Scope, Statics::Map)
          => SetItem(X) getStatics(Ids, Scope, Statics)
          requires kpair(X, Scope) in_keys(Statics)
     rule getStatics(SetItem(X::CId) Ids::Set, Scope::Scope, Statics::Map)
          => getStatics(Ids, Scope, Statics)
          requires notBool kpair(X, Scope) in_keys(Statics)
     rule getStatics(.Set, _, _) => .Set

endmodule
