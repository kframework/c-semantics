module LIBC-SETJMP
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-IO-BUFFERED-SYNTAX

     imports C-CONFIGURATION

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


     // The (apparent) return value from setjmp indicates whether control
     // reached that point normally or from a call to longjmp
     // fixme check bounds
     // fixme obviously need to rework configuration to make this easy
     syntax CValue ::= bag(K)

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
     // fixme doesn't check if loc:Int is const
     rule [setjmp]:
          <k> (prepareBuiltin(Identifier("setjmp"),
               hrItem(tv(Loc:SymLoc, t(_, pointerType(t(_,
                    structType(global(Identifier("__jmp_buf_tag"), "builtin"))))))))
               => ignoreLocals
                    ~> writeBytes(Loc, ListItem(bag(
                         <thread-state>
                              <thread-continuation> K:K </thread-continuation>
                              <saved-thread-local>C</saved-thread-local>
                         </thread-state>
                    )))
                    ~> tv(0, t(.Set, int))
               )
               ~> K:K
          </k>
          C:ThreadLocalCell
          [structural]

     syntax KItem ::= "longjmp-aux" "(" K "," K ")" [strict(2)]
     context longjmp-aux(HOLE:KItem => reval(HOLE), _) [result(RValue)]
     rule [longjmp-prepare]:
          prepareBuiltin(Identifier("longjmp"),
               hrItem(V:KResult) hs::
               hrItem(V':KResult))
          => longjmp-aux(*(V), V')
          [structural]

     // fixme: memory leak here with extra ignoreLocals.  needed for recursive
     // setjmp/longjmp as in Looping.c
     rule [longjmp]:
          <k>
               longjmp-aux(tv(agg(ListItem(bag(
                    <thread-state>
                         <thread-continuation> K:K </thread-continuation>
                         <saved-thread-local>C:ThreadLocalCell</saved-thread-local>
                    </thread-state>
               ))), t(_, structType(global(Identifier("__jmp_buf_tag"), "builtin")))),
                    tv(I:Int, t(_, int))) ~> _
               => ignoreLocals
                    ~> #if I:Int ==Int 0
                         #then tv(1, t(.Set, int))
                         #else tv(I:Int, t(.Set, int)) #fi
                    ~> K:K
          </k>
          (<thread-local> _ </thread-local> => C)
          [structural]
endmodule
