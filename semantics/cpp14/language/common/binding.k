module CPP-BINDING-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= bind(List, List, List) [klabel(bindCpp)]
     syntax KItem ::= bindParam(CId, CPPType, Init) [klabel(bindParamCpp3)]

endmodule

module CPP-BINDING
     imports CPP-BINDING-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports CPP-TYPING-SYNTAX

     rule <k> (.K => bindParam(X, T, V))
          ~> bind(
               (ListItem(X::CId) => .List) _,
               (ListItem(T:CPPType) => .List) _,
               (ListItem(V::Init) => .List) _)
          ...</k>

     rule bind(.List, ListItem(variadic), Vs::List)
          => bindVariadics(Vs)

     rule bind(.List, .List, .List) => .K

     syntax KItem ::= bindVariadics(List) [klabel(bindVariadicsCpp)]
     rule bindVariadics(.List) => .K
endmodule
