module CPP-BINDING-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= bind(List, List, List, Int) [klabel(bindCpp)]
     syntax KItem ::= bindParam(Int, CPPType, Init) [klabel(bindParamCpp3)]

endmodule

module CPP-BINDING
     imports CPP-BINDING-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports CPP-TYPING-SYNTAX

     rule <k> (.K => bindParam(I, T, V))
          ~> bind(
               (ListItem(T:CPPType) => .List) _,
               (ListItem(_) => .List) _,
               (ListItem(V::Init) => .List) _,
               (I::Int => I +Int 1))
          ...</k>

     rule bind(ListItem(variadic), ListItem(variadic), Vs::List, I::Int)
          => bindVariadics(Vs, I)

     rule bind(.List, .List, .List, _) => .K

     syntax KItem ::= bindVariadics(List, Int) [klabel(bindVariadicsCpp)]
     rule bindVariadics(.List, _) => .K
endmodule
