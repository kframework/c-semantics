require "modules/k-functional-visitor.k"

require "cil-common.k"


module CIL-CONST-PROPAGATION
  imports K-FUNCTIONAL-VISITOR 
  imports CIL-COMMON

  /*
   * Propagate constants
   */
  syntax K ::= "propagate-constants" "(" CId ")"
  rule
    <k> propagate-constants(F:CId) ...</k>
    <fun>...
      <fun-id> F </fun-id>
      <body> { _:VarDecls { Ss:Stmts } } </body>
    ...</fun>
    <propagate-constants>
      <propagate-constants-enabled> false => true </propagate-constants-enabled>
      <propagate-constants-stmts> _ => Ss </propagate-constants-stmts>
      <after-stmts> _ => .Stmts </after-stmts>
      <constant-table> _ => .Map </constant-table>
    </propagate-constants>
  [structural]


  syntax Stmt ::= "assign-helper" "(" CId "," K ")"
  rule
    <propagate-constants-stmts>
      X:CId = TV:Int; Ss1:Stmts => Ss1
    </propagate-constants-stmts>
    <constant-table> M:Map (.Map => X |-> TV) </constant-table>
    <after-stmts> Ss2:Stmts => Ss2 @Stmts X = TV; </after-stmts>
    when notBool(X in keys(M))
  [structural]
  rule
    <propagate-constants-stmts>
      X:CId = TV:Int; Ss1:Stmts => Ss1
    </propagate-constants-stmts>
    <after-stmts> Ss2:Stmts => Ss2 @Stmts X = TV; </after-stmts>
    <constant-table>... X |-> (_ => TV) ...</constant-table>
  [structural]
  rule
    <propagate-constants-stmts>
      (X:CId = E:Exp; => assign-helper(X, helper(E, M))) Ss:Stmts
    </propagate-constants-stmts>
    <constant-table> M:Map </constant-table>
    when isInt(E) =/=K true
  [structural]
  rule
    <propagate-constants-stmts>
      assign-helper(X:CId, TV:Int) Ss1:Stmts => Ss1
    </propagate-constants-stmts>
    <constant-table> M:Map (.Map => X |-> TV) </constant-table>
    <after-stmts> Ss2:Stmts => Ss2 @Stmts X = TV; </after-stmts>
    when notBool(X in keys(M))
  [structural]
  rule
    <propagate-constants-stmts>
      assign-helper(X:CId, TV:Int) Ss1:Stmts => Ss1
    </propagate-constants-stmts>
    <after-stmts> Ss2:Stmts => Ss2 @Stmts X = TV; </after-stmts>
    <constant-table>... X |-> (_ => TV) ...</constant-table>
  [structural]
  rule
    <propagate-constants-stmts>
      assign-helper(X:CId, E:Exp) Ss1:Stmts => Ss1
    </propagate-constants-stmts>
    <after-stmts> Ss2:Stmts => Ss2 @Stmts X = E; </after-stmts>
    when isInt(E) =/=K true 
  [structural]
  rule
    <propagate-constants-stmts>
      return (E:Exp); Ss1:Stmts => Ss1
    </propagate-constants-stmts>
    <after-stmts> Ss2:Stmts => Ss2 @Stmts return (helper(E, M)); </after-stmts>
    <constant-table> M:Map </constant-table>
  [structural]



  syntax Exp ::= helper(Exp, Map) [function]
  rule helper(E:Exp, M:Map) => #visit(E, 'visitCId, Map2K(M), 'isVisitCId)
  syntax Bool ::= isVisitCId(K) [function]
  syntax K ::= visitCId(K, K) [function]
  rule isVisitCId(X:CId) => true
  rule visitCId(X:CId, Map2K((X |-> TV:Int _:Map))) => TV
  rule visitCId(X:CId, Map2K(M:Map)) => X
  when notBool(X in keys(M))

endmodule

