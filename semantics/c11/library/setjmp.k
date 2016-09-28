module LIBC-SETJMP
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-BUILTIN-SYNTAX
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports INT
     imports K-EQUAL

     /*@
     \fromStandard{\source[n1570]{\para{7.13}{1--3}}}{
     The header \header{<setjmp.h>} defines the macro \cinline{setjmp}, and
     declares one function and one type, for bypassing the normal function call
     and return discipline.

     The type declared
     \cdisplay{jmp_buf}
     which is an array type suitable for holding the information needed to
     restore a calling environment. The environment of a call to the
     \cinline{setjmp} macro consists of information sufficient for a call to
     the \cinline{longjmp} function to return execution to the correct block
     and invocation of that block, were it called recursively. It does not
     include the state of the floating-point status flags, of open files, or of
     any other component of the abstract machine.

     It is unspecified whether \cinline{setjmp} is a macro or an identifier
     declared with external linkage. If a macro definition is suppressed in
     order to access an actual function, or a program defines an external
     identifier with the name \cinline{setjmp}, the behavior is undefined.
     }*/


     syntax KItem ::= "ignoreLocals"

     // there seems to be a problem here related to locals.  what if longjmp is
     // never called?
     rule [ignoreLocals]:
          <k> ignoreLocals => .K ...</k>
          <local-addresses> _ => .Set </local-addresses>
          [structural]

     /*@
     \begin{lrbox}{\LstBox}
     \begin{lstlisting}
     #include <setjmp.h>
     int setjmp(jmp_buf env);
     \end{lstlisting}
     \end{lrbox}
     \fromStandard{\source[n1570]{\para{7.13.1.1}{1--5}}}{
     \Synopsis
     \usebox{\LstBox}

     \Description
     The \cinline{setjmp} macro saves its calling environment in its
     \cinline{jmp_buf} argument for later use by the \cinline{longjmp}
     function.

     \Returns
     If the return is from a direct invocation, the \cinline{setjmp} macro
     returns the value zero. If the return is from a call to the
     \cinline{longjmp} function, the \cinline{setjmp} macro returns a nonzero
     value.

     \Limits
     An invocation of the \cinline{setjmp} macro shall appear only in one of
     the following contexts:
     \begin{itemize}
     \item the entire controlling expression of a selection or iteration
     statement;

     \item one operand of a relational or equality operator with the other
     operand an integer constant expression, with the resulting expression
     being the entire controlling expression of a selection or iteration
     statement;

     \item the operand of a unary \cinline{!} operator with the resulting
     expression being the entire controlling expression of a selection or
     iteration statement; or

     \item the entire expression of an expression statement (possibly cast to
     \cinline{void}).

     \end{itemize}

     If the invocation appears in any other context, the behavior is undefined.
     }*/
     // The (apparent) return value from setjmp indicates whether control
     // reached that point normally or from a call to longjmp
     rule [setjmp]:
          <k> (builtin("__setjmp", Ptr:RValue)
               => ignoreLocals
               ~> addJmpBuf(!N:Int, Ptr, K, C)
               ~> tv(0, utype(int))
               )
               ~> K:K
          </k>
          C:ThreadLocalCell
          [structural]

     syntax KItem ::= jmpBuf(K, K)
     syntax KItem ::= addJmpBuf(Int, RValue, K, K)

     rule <k> addJmpBuf(N'::Int, JmpBufPtr::RValue, K:K, C:K)
               => Computation((* JmpBufPtr) := tv(N', utype(innerType(jmp_buf))))
          ...</k>
          <jmp-bufs>... .Map => N' |-> jmpBuf(K, C) </jmp-bufs>
          [structural]

     syntax KItem ::= "longjmp'" "(" K "," K ")" [strict(2)]
     context longjmp'(HOLE:KItem => reval(HOLE), _) [result(RValue)]
     rule builtin("longjmp", V:RValue, V':RValue) => longjmp'(*(V), V')
          [structural]

     // fixme: memory leak here with extra ignoreLocals.  needed for recursive
     // setjmp/longjmp as in Looping.c
     rule [longjmp]:
          <k> longjmp'(tv(N:Int, _), tv(I:Int, _))
                ~> _
                => ignoreLocals
                ~> #if (I ==Int 0)
                      #then tv(1, utype(int))
                      #else tv(I, utype(int)) #fi
                ~> K
          </k>
          <thread-local> _::Bag => C </thread-local>
          <jmp-bufs>...
               N |-> jmpBuf(K:K, (<thread-local> C::Bag </thread-local>))
          ...</jmp-bufs>
          [structural]
endmodule
