module CPP-TRANSLATION-PROCESS-LABEL-SYNTAX
     imports BASIC-K
     syntax KItem ::= calculateGotoMap(K)
endmodule

module CPP-TRANSLATION-PROCESS-LABEL
     imports CPP-TRANSLATION-PROCESS-LABEL-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports COMPAT-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX

     syntax KItem ::= "waitingOnGotoMap"

     rule <k> calculateGotoMap(K:K) => waitingOnGotoMap ...</k>
          <goto-map-calc>
               .Bag => (<goto-calc>...
                         <computation>
                              K
                         </computation>
                    ...</goto-calc>)
          </goto-map-calc>

     rule <k> waitingOnGotoMap ...</k>
          ((<goto-calc>
               <computation> .K </computation>
          ...</goto-calc>) => .Bag)

     rule <k> waitingOnGotoMap => .K ...</k>
          <goto-map-calc> .Bag </goto-map-calc>

     rule <k> waitingOnGotoMap ...</k>
          <computation> (LabelStmt(Target::CId, L::List) => listToK(L)) ~> K:K </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-loop-stack> LoopStack::List </goto-loop-stack>
          <decl-stack> DeclStack::List </decl-stack>
          <curr-tr-scope> blockScope(_, F::SymBase, _) </curr-tr-scope>
          <goto-nesting-depth> Depth::Int </goto-nesting-depth>
          <goto-block-history> BlockHistory::List </goto-block-history>
          <goto-map> M::Map =>
               M[F, Target <- gotoObject(Depth, BlockHistory,
                    (listToK(L) ~> K ~> Tail), LoopStack, DeclStack)]
          </goto-map>
          requires notBool (Target in_keys({M[F] orDefault .Map}:>Map))

     rule <k> waitingOnGotoMap ...</k>
          <computation> pushBlock(Tag::Int) => .K ...</computation>
          <goto-nesting-depth> N::Int => N +Int 1 </goto-nesting-depth>
          <goto-block-history> .List => ListItem(Tag) ...</goto-block-history>

     rule <k> waitingOnGotoMap ...</k>
          <computation> popBlock(_) => .K ...</computation>
          <goto-nesting-depth> I::Int => I -Int 1 </goto-nesting-depth>
          <goto-block-history> ListItem(_) => .List ...</goto-block-history>
          requires I >Int 0

     rule <k> waitingOnGotoMap ...</k>
          <computation> ExpressionStmt(_) => .K ...</computation>

     rule <k> waitingOnGotoMap ...</k>
          <computation> BreakStmt() => .K ...</computation>

     rule <k> waitingOnGotoMap ...</k>
          <computation> ReturnOp(_, _) => .K ...</computation>

     rule <k> waitingOnGotoMap ...</k>
          <computation> GotoStmt(_) => .K ...</computation>

     rule <k> waitingOnGotoMap ...</k>
          <computation> addToConstructed(...) => .K ...</computation>

     rule <k> waitingOnGotoMap ...</k>
          <computation> writeVTables => .K ...</computation>

     rule <k> waitingOnGotoMap ...</k>
          <computation> L:CabsLoc => .K ...</computation>
          <curr-tr-program-loc> _ => L </curr-tr-program-loc>

     rule <k> waitingOnGotoMap ...</k>
          <computation>
               declareNonStaticObjectExec(X::CId, T::CPPType, Init:K, Type::DeclarationType, D::Duration, S::Set) => .K
          ...</computation>
          <decl-stack>...
               .List
               => ListItem(frozenDeclaration(Depth, BlockNum,
                    declareNonStaticObjectExec(X, T, Init, Type, D, S)))
          </decl-stack>
          <goto-nesting-depth> Depth::Int </goto-nesting-depth>
          <goto-block-history> ListItem(BlockNum::Int) ...</goto-block-history>

     rule <k> waitingOnGotoMap ...</k>
          <computation>
               declareLocalStaticObject(X::CId, Base::SymBase, T::CPPType) => .K
          ...</computation>
          <decl-stack>...
               .List
               => ListItem(frozenDeclaration(Depth, BlockNum,
                    declareLocalStaticObject(X, Base, T)))
          </decl-stack>
          <goto-nesting-depth> Depth::Int </goto-nesting-depth>
          <goto-block-history> ListItem(BlockNum::Int) ...</goto-block-history>

     rule <k> waitingOnGotoMap ...</k>
          <goto-calc>
               <computation>
                    (ForStmt(Control:Expr, Post::K, S::K) => .K)
                    ~> K:K
               </computation>
               <computation-tail> Tail:K </computation-tail>
               B::Bag
               <goto-nesting-depth> N::Int </goto-nesting-depth>
               <goto-block-history>
                    ListItem(Num::Int) OldBlockHistory::List
               </goto-block-history>
               <goto-loop-stack> OldLoopStack::List </goto-loop-stack>
          </goto-calc>
          (.Bag => <goto-calc>
               <computation> S </computation>
               <computation-tail>
                    Post
                    ~> loopMarked
                    ~> ForStmt(Control, Post, S)
                    ~> popLoop
                    ~> K
                    ~> Tail
               </computation-tail>
               B
               <goto-nesting-depth> N </goto-nesting-depth>
               <goto-block-history>
                    ListItem(Num) OldBlockHistory
               </goto-block-history>
               <goto-loop-stack>
                    ListItem(kpair(Num, (K ~> Tail)))
                    OldLoopStack
               </goto-loop-stack>
          </goto-calc>)

     rule <k> waitingOnGotoMap ...</k>
          <computation>
               (.K => S ~> loopMarked)
               ~> WhileStmt(_:Expr, S::K)
               ~> (.K => popLoop)
               ~> K:K
          </computation>
          <computation-tail> Tail:K </computation-tail>
          <goto-block-history> ListItem(Num::Int) ...</goto-block-history>
          <goto-loop-stack>
               (.List => ListItem(kpair(Num, (K ~> Tail))))
          ...</goto-loop-stack>

     rule <k> waitingOnGotoMap ...</k>
          <computation>
               (loopMarked ~> WhileStmt(_:Expr, _) => .K) ~> popLoop ~> _
          </computation>

     rule <k> waitingOnGotoMap ...</k>
          <goto-calc>
               <computation>
                    (IfStmt(_:Expr, S1::K, S2::K) => .K) ~> K:K
               </computation>
               <computation-tail> Tail:K </computation-tail>
               B::Bag
          </goto-calc>
          (.Bag => <goto-calc>
               <computation> S1 </computation>
               <computation-tail> K ~>  Tail </computation-tail>
               B
          </goto-calc>)
          (.Bag => <goto-calc>
               <computation> S2 </computation>
               <computation-tail> K ~>  Tail </computation-tail>
               B
          </goto-calc>)

     rule <k> waitingOnGotoMap ...</k>
          <computation> popLoop => .K ...</computation>
          <goto-loop-stack> ListItem(_) => .List ...</goto-loop-stack>

     rule <k> waitingOnGotoMap ...</k>
          <goto-calc>
               <computation>
                    (TryStmt(S::K, .List) => .K) ~> K:K
               </computation>
               <computation-tail> Tail:K </computation-tail>
               B::Bag
          </goto-calc>
          (.Bag => <goto-calc>
               <computation> S </computation>
               <computation-tail> K ~> Tail </computation-tail>
               B
          </goto-calc>)

     rule <k> waitingOnGotoMap ...</k>
          <goto-calc>
               <computation>
                    TryStmt(_, (ListItem(CatchOp(T::CPPType, S::K)) => .List) L::List) ~> K:K
               </computation>
               <computation-tail> Tail:K </computation-tail>
               B::Bag
          </goto-calc>
          (.Bag => <goto-calc>
               <computation> S </computation>
               <computation-tail> K ~> Tail </computation-tail>
               B
          </goto-calc>)

     rule <k> waitingOnGotoMap ...</k>
          <goto-calc>
               <computation>
                    TryStmt(_, (ListItem(CatchAnyOp(S::K)) => .List) L::List) ~> K:K
               </computation>
               <computation-tail> Tail:K </computation-tail>
               B::Bag
          </goto-calc>
          (.Bag => <goto-calc>
               <computation> S </computation>
               <computation-tail> K ~> Tail </computation-tail>
               B
          </goto-calc>)

endmodule
