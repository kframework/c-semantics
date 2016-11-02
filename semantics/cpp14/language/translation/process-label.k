module CPP-PROCESS-LABEL-SYNTAX
     imports BASIC-K
     syntax KItem ::= calculateGotoMap(K)
endmodule

module CPP-PROCESS-LABEL
     imports CPP-PROCESS-LABEL-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports COMPAT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX

     syntax KItem ::= "waitingOnGotoMap"
     rule <k> calculateGotoMap(K:K) => waitingOnGotoMap ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
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
          <curr-scope> blockScope(_, F::SymBase, _) </curr-scope>
          <goto-nesting-depth> Depth::Int </goto-nesting-depth>
          <goto-block-history> BlockHistory::List </goto-block-history>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map> M::Map =>
               M[F, Target <- gotoObject(Depth, BlockHistory,
                    (listToK(L) ~> K ~> Tail), LoopStack, DeclStack)]
          </goto-map>
          requires notBool (Target in_keys({M[F]}:>Map))

     rule <k> waitingOnGotoMap ...</k>
          <computation> pushBlock(Tag::Int) => .K ...</computation>
          <goto-nesting-depth> N::Int => N +Int 1 </goto-nesting-depth>
          <goto-block-history> .List => ListItem(Tag) ...</goto-block-history>
     rule <k> waitingOnGotoMap ...</k>
          <computation> popBlock => .K ...</computation>
          <goto-nesting-depth> I::Int => I -Int 1 </goto-nesting-depth>
          <goto-block-history> ListItem(_) => .List ...</goto-block-history>
          requires I >Int 0

     rule <k> waitingOnGotoMap ...</k>
          <computation> ExpressionStmt(_) => .K ...</computation>
     rule <k> waitingOnGotoMap ...</k>
          <computation> ReturnOp(_) => .K ...</computation>
     rule <k> waitingOnGotoMap ...</k>
          <computation> GotoStmt(_) => .K ...</computation>

     rule <k> waitingOnGotoMap ...</k>
          <computation>
               declareNonStaticObject(X::CId, T::CPPType, Init:K, Type::DeclarationType, D::Duration, S::Set) => .K
          ...</computation>
          <decl-stack>...
               .List
               => ListItem(frozenDeclaration(Depth, BlockNum,
                    declareNonStaticObject(X, T, Init, Type, D, S)))
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
                    (ForStmt(Control:Expr, Post::Stmt, S::Stmt) => .K)
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
          <goto-calc>
               <computation>
                    (IfStmt(_:Expr, S1::Block, S2::Block) => .K) ~> K:K
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

endmodule
