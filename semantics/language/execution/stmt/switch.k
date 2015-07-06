module C-STMT-SWITCH
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     // switch num, promoted value of controlling exp, int value of exp
     syntax KItem ::= handleSwitch(Int, K) [strict(2)]

     /*@ \fromStandard{\source[n1570]{\para{6.8.4.2}{4}}}{
     A \cinline{switch} statement causes control to jump to, into, or past the
     statement that is the \emph{switch body}, depending on the value of a
     controlling expression, and on the presence of a \cinline{default} label
     and the values of any \cinline{case} labels on or in the switch body. A
     \cinline{case} or \cinline{default} label is accessible only within the
     closest enclosing \cinline{switch} statement.
     }

     \fromStandard{\source[n1570]{\para{6.8.4.2}{5}}}{
     The integer promotions are performed on the controlling expression. The
     constant expression in each \cinline{case} label is converted to the
     promoted type of the controlling expression. If a converted value matches
     that of the promoted controlling expression, control jumps to the statement
     following the matched \cinline{case} label. Otherwise, if there is a
     default label, control jumps to the labeled statement. If no converted
     \cinline{case} constant expression matches and there is no
     \cinline{default} label, no part of the switch body is executed.
     }*/

     // Promotions already handled.
     rule Switch(SN:Int, tv(V:K, T:IntegerType), _)
          => sequencePoint
               ~> handleSwitch(SN, tv(V, T))
          [structural]

     rule <k> handleSwitch(SN:Int, V:RValue)
               => #handleSwitch-aux(SN, V, .K, M)
          ...</k>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>... F |-> map(M:Map) ...</goto-map>
          [structural]

     // K to be evaluated, val it should be, casehelper
     syntax KItem ::= tryCase(RValue, RValue, K)

     syntax KItem ::= "#handleSwitch-aux" "(" Int "," RValue "," K "," Map ")"

     rule #handleSwitch-aux(_, _, .K, .Map) => .K
          [structural]

     rule #handleSwitch-aux(SN:Int, V:RValue, .K,
               (Key:K |-> _) M:Map)
          => #handleSwitch-aux(SN, V, Key, M)
          [structural]

     rule #handleSwitch-aux(SN:Int, V:RValue, caseLabel(SN, Exp:K), M:Map)
          => (tryCase(Exp, V, caseLabel(SN, Exp))
          ~> #handleSwitch-aux(SN, V, .K, M))
          requires Exp =/=K #klabel(`Default`)
          [structural]

     //  if all that's left is a default, do it
     rule #handleSwitch-aux(SN:Int, V:RValue, caseLabel(SN:Int, #klabel(`Default`)), M:Map)
          => (#handleSwitch-aux(SN, V, .K, M)
          ~> Goto(caseLabel(SN, #klabel(`Default`))))
          [structural]

     rule #handleSwitch-aux(SN:Int, _, (caseLabel(SN':Int, _:K) => .K), _)
          requires SN =/=Int SN'
          [structural]

     rule #handleSwitch-aux(_:Int, _:RValue, (K:K => .K), _)
          requires getKLabel(K) =/=K #klabel(caseLabel)
          [structural]

     rule tryCase(
               (tv(V:K, T':Type) => stripConstants(cast(T, tv(V, T')))),
               tv(_, T:Type), _)
          requires T =/=Type T'
          [structural]
     rule tryCase(tv(V':K, T':Type), tv(V:K, T:Type), _) => .K
          requires (V =/=K V') andBool (T ==Type T')
          [structural]
     //  match found in value and type, goto it
     //  don't need to erase the rest of K since we're GOTOing
     rule tryCase(tv(V:CValue, T':Type), tv(V:CValue, T:Type), CaseLabel:K)
          => Goto(CaseLabel)
          requires T ==Type T'
          [structural]

endmodule

