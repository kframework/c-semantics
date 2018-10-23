module LIBC-SETJMP
     imports LIBC-BUILTIN-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports K-EQUAL
     imports C-CHECK-RESTRICT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-IO-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports DELETE-OBJECT-SYNTAX
     imports LIBC-TYPES-SYNTAX

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
     rule <k> (builtin("_setjmp", Ptr:RValue)
               => addJmpBuf(!N:Int, Ptr, K, C)
               ~> success)
               ~> K:K
          </k>
          C:ThreadLocalCell
          [structural]

     syntax JmpBuf ::= jmpBuf(K, K, SymBase)
     syntax KResult ::= JmpBuf
     syntax KItem ::= addJmpBuf(Int, RValue, K, K)

     rule <k> addJmpBuf(N::Int, JmpBufPtr::RValue, K:K, C:K)
               => Computation((* JmpBufPtr) := tv(opaque(N, utype(innerType(jmp_buf))), utype(innerType(jmp_buf))))
          ...</k>
          <call-stack> ListItem(
               <call-stack-frame>...
                    <stack-function-control> <function-control>...
                         <env>... funLabel |-> B::SymBase ...</env>
                    ...</function-control> </stack-function-control>
               ...</call-stack-frame>)
          ...</call-stack>
          <jmp-bufs>... .Map => N |-> jmpBuf(K, C, B) </jmp-bufs>
          [structural]

     syntax KItem ::= longjmp(K, RValue) [strict(1)]
     rule builtin("longjmp", V:RValue, V':RValue) => longjmp(getJmpBuf(*(V)), V')
          [structural]

     syntax KItem ::= getJmpBuf(K)
     context getJmpBuf(HOLE:KItem => reval(HOLE)) [result(RValue)]
     rule <k> (.K => UNDEF("SETJMP1", "'longjmp' invoked to restore a nonexistent environment."))
               ~> getJmpBuf(tv(V::CValue, _))
          ...</k>
          <jmp-bufs> JmpBufs::Map </jmp-bufs>
          requires notBool (jmpBufId(V) in_keys(JmpBufs))
     rule <k> getJmpBuf(tv(opaque(N:Int, _), _)) => JmpBuf ...</k>
          <jmp-bufs>... N |-> JmpBuf::JmpBuf ...</jmp-bufs>

     syntax Int ::= jmpBufId(CValue) [function]
     rule jmpBufId(opaque(N:Int, _)) => N
     rule jmpBufId(_) => -1 [owise]

     rule <k> (.K => popBlock)
               ~> longjmp(jmpBuf(_, _, B::SymBase), _)
          ...</k>
          <block-history> ListItem(_) ...</block-history>
          <block-stack> ListItem(_) ...</block-stack>
          <env> Env:Map </env>
          <mem> Mem:Map </mem>
          requires B in_keys(Mem)
               andBool Env[funLabel] =/=K B
          [structural]
     rule <k> (.K => deleteObjects(Locals) ~> exitRestrictBlock(Locals))
               ~> longjmp(jmpBuf(_, _, B::SymBase), _)
          ...</k>
          (<function-control>...
               <env> Env:Map </env>
               <block-stack> .List </block-stack>
               <block-history> .List </block-history>
               <local-addresses> Locals::Set </local-addresses>
          ...</function-control> => C)
          <call-stack>
               ListItem(
                    <call-stack-frame>...
                         <stack-function-control>
                              C:FunctionControlCell
                         </stack-function-control>
                         <stack-lang-linkage> CLinkage </stack-lang-linkage>
                    ...</call-stack-frame>
               ) => .List
          ...</call-stack>
          <mem> Mem:Map </mem>
          requires B in_keys(Mem)
               andBool Env[funLabel] =/=K B
          [structural]
     rule <k> longjmp(jmpBuf(K:K, C:ThreadLocalCell, B::SymBase), tv(I:Int, _))
               ~> _
               => deleteLocals(Locals)
               ~> #if (I ==Int 0)
                    #then tv(1, utype(int))
                    #else tv(I, utype(int)) #fi
               ~> K
          </k>
          (<thread-local>...
               <env>... funLabel |-> B ...</env>
               <local-addresses> Locals::Set </local-addresses>
          ...</thread-local> => C)
          <mem> Mem:Map </mem>
          requires B in_keys(Mem)
          [structural]

     rule <k> (.K => UNDEF("SETJMP2",
               "'longjmp' invoked to restore the environment of a function that has since terminated."))
               ~> longjmp(jmpBuf(_, _, B::SymBase), _)
          ...</k>
          <mem> Mem:Map </mem>
          requires notBool B in_keys(Mem)
          [structural]

     syntax KItem ::= deleteLocals(Set)
     rule <k> deleteLocals(Locals::Set)
               => deleteObjects(Locals -Set Locals')
          ...</k>
          <local-addresses> Locals'::Set </local-addresses>

endmodule
