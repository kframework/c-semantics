module CPP-BINDING-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= bind(List, List, List) [klabel(bindCpp)]
     syntax KItem ::= bindParam(CId, CPPType, Init) [klabel(bindParamCpp3)]

     syntax KItem ::= setThis(Expr) [strict]
endmodule

module CPP-BINDING
     imports CPP-BINDING-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> (.K => bindParam(X, T, V))
          ~> bind(
               (ListItem(X::CId) => .List) _,
               (ListItem(T:CPPType) => .List) _,
               (ListItem(V::Init) => .List) _)
          ...</k>

     rule <k> (.K => setThis(V))
          ~> bind(
               _,
               (ListItem(implicitObjectParameter(T::CPPType)) => .List) _,
               (ListItem(V:PRVal) => .List) _)
          ...</k>
          requires T =/=K type(no-type)
     rule bind(_,
               (ListItem(implicitObjectParameter(t(... st: no-type))) => .List) _,
               (ListItem(_) => .List) _)
        

     rule bind(.List, ListItem(variadic), Vs::List)
          => bindVariadics(Vs)

     rule bind(.List, .List, .List) => .K

     syntax KItem ::= bindVariadics(List) [klabel(bindVariadicsCpp)]
     rule bindVariadics(.List) => .K

     rule <k> setThis(Obj:PRVal) => .K ...</k>
          <this> _ => Obj </this>

     rule <k> beginConstruction(Obj:LVal) => Obj ...</k>
          <constructing> _ => Obj </constructing>
     rule <k> endConstruction(Obj:LVal, IsConstructor::Bool) => Obj ...</k>
          <constructing> _ => .K </constructing>
          <locally-constructed> .List => ListItem(ktriple(Obj, true, IsConstructor)) ...</locally-constructed>
endmodule
