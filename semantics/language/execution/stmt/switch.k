module C-STMT-SWITCH
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports COMPAT-SYNTAX

     // switch num, promoted value of controlling exp, int value of exp
     syntax K ::= handleSwitch(Int, K) [strict(2)]
     syntax K ::= "handleSwitch-aux" "(" K "," RValue "," K ")"

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

     rule Switch(SN:Int, tv(V:K, T:Type), _)
          => sequencePoint
               ~> handleSwitch(SN, cast(promote(T), tv(V, T)))
          when hasIntegerType(T)
          [structural]

     rule <k> handleSwitch(SN:Int, V:RValue)
               => handleSwitch-aux(SN, V, map(M))
          ...</k>
          <curr-function> F:CId </curr-function>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>... F |-> map(M:Map) ...</goto-map>
          [structural]

     // K to be evaluated, val it should be, casehelper
     syntax K ::= tryCase(K, RValue, K) [strict(1(context('reval), result(RValue)))]

     rule (. => tryCase(Exp, V, CaseHelper))
          ~> handleSwitch-aux(SN:Int, V:RValue,
               map((_ ((genLabel(SN:Int, Exp:K) |-> CaseHelper:K) => .Map))))
          when Exp =/=K l('Default)
          [structural]

     //  if all that's left is a default, do it
     rule handleSwitch-aux(SN:Int, _, map((genLabel(SN:Int, l('Default)) |-> _)))
          => Goto(genLabel(SN, l('Default)))
          [structural]

     //  if there's nothing left, no case matches
     rule handleSwitch-aux(_, _, map(.Map)) => .
          [structural]

     rule handleSwitch-aux(SN:Int, _,
               map((_ ((genLabel(SN':Int, _) |-> _) => .Map))))
          when SN =/=Int SN'
          [structural]
     rule handleSwitch-aux(_:Int, _, map((_ ((L:KLabel(_) |-> _) => .Map))))
          when L =/=KLabel 'genLabel
          [structural]

     rule tryCase(
               (tv(V:K, T':Type) => cast(T, tv(V, T'))),
               tv(_, T:Type), _)
          when T =/=Type T'
          [structural]
     rule tryCase(tv(V':K, T':Type), tv(V:K, T:Type), _) => .
          when (V =/=K V') andBool (T ==Type T')
          [structural]
     //  match found in value and type, goto it
     //  don't need to erase the rest of K since we're GOTOing
     rule tryCase(tv(V:CValue, T':Type), tv(V:CValue, T:Type), CaseHelper:K)
          => Goto(CaseHelper)
          when T ==Type T'
          [structural]
endmodule
