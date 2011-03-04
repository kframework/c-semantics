/* -*- mode: C -*-
 *
 *
 * Copyright (c) 2007, 2008 The University of Utah
 * All rights reserved.
 *
 * This file is part of `csmith', a random generator of C programs.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

// removed some unused functions
 
#ifndef PLATFORM_GENERIC_H
#define PLATFORM_GENERIC_H

/*****************************************************************************/

#ifdef STANDALONE
extern int printf (const char *, ...);
#else
#include <stdio.h>
#endif

static void
platform_main_begin(void)
{
	/* Nothing to do. */
}

#define MB (1<<20)

// FIXME!  These are specific to Linux

#define STACK_TOP 0xc0000000
#define STACK_SIZE (8*MB) 
#define STACK_BOTTOM (STACK_TOP-STACK_SIZE)
#define stack_var(p) (((long)(&(p))<=STACK_TOP)&&((long)(&(p))>=STACK_BOTTOM))

#define GLOBAL_BOTTOM (128*MB)
#define GLOBAL_SIZE (8*MB)
#define GLOBAL_TOP (GLOBAL_BOTTOM+GLOBAL_SIZE)
#define global_var(p) (((long)(&(p))<=GLOBAL_TOP)&&((long)(&(p))>=GLOBAL_BOTTOM))

/*****************************************************************************/

#endif /* PLATFORM_GENERIC_H */

/*
 * Local Variables:
 * c-basic-offset: 4
 * tab-width: 4
 * End:
 */

/* End of file. */
