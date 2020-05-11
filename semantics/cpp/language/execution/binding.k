module CPP-BINDING-SYNTAX
     imports INT-SYNTAX
     imports LIST
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= bind(List, List, List) [klabel(bindCpp)]

     syntax KItem ::= bindParam(CId, CPPType, Init) [klabel(bindParamCpp3)]

     syntax KItem ::= setThis(K)
endmodule

module CPP-EXECUTION-BINDING
     imports CPP-BINDING-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-STMT-BLOCK-SYNTAX
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> setThis(.K) => .K ...</k>
          <this> _ => .K </this>

     rule setThis(E:Expr) => #setThis(E)

     syntax KItem ::= #setThis(Expr) [strict(c)]

     rule <k> (.K => bindParam(X, T, V))
          ~> bind(
               (ListItem(X::CId) => .List) _,
               (ListItem(T:CPPType) => .List) _,
               (ListItem(V::Init) => .List) _)
          ...</k>

     rule <k> (.K => #setThis(V))
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

     rule <k> #setThis(Obj:PRVal) => .K ...</k>
          <this> _ => Obj </this>

     rule <k> beginConstruction(Obj:LVal, IsBaseClassSubobject:Bool) => Obj ...</k>
          <constructing> Old::K => Obj </constructing>
          <constructing-history>
               .List => ListItem(<constructing>Old</constructing>)
          ...</constructing-history>
          <most-derived-class>
               MostDerived:K => #if IsBaseClassSubobject #then MostDerived #else type(Obj) #fi
          </most-derived-class>

     rule <k> endConstruction(Obj:LVal, IsConstructor::Bool) => finishConstruction(Obj, IsConstructor) ...</k>
          <constructing> _ => Old </constructing>
          <constructing-history>
               ListItem(<constructing> Old::K </constructing>) => .List
          ...</constructing-history>

     rule <k> finishConstruction(Obj:LVal, IsConstructor:Bool) => Obj ...</k>
          <locally-constructed> .List =>
          #if IsConstructor #then
               ListItem(lcentry(Obj, true, true, true))
          #else .List #fi
          ...</locally-constructed>

     rule <k> writeVTables => write(Loc, prv(vtable(MDC), noTrace, type(pointerType(type(void)))), type(pointerType(type(void)))) ...</k>
          <curr-scope> blockScope(C::Class :: _, _, _) </curr-scope>
          <this> prv(Loc::SymLoc, _, _) </this>
          <most-derived-class> t(... st: classType(MDC::Class)) </most-derived-class>
          requires hasVirtualMembers(type(classType(C)))

     rule <k> writeVTables => .K ...</k>
          <curr-scope> blockScope(C::Class :: _, _, _) </curr-scope>
          requires notBool hasVirtualMembers(type(classType(C)))
endmodule
