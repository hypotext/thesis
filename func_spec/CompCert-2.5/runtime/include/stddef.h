/* This file is part of the Compcert verified compiler.
 *
 * Copyright (c) 2015 Institut National de Recherche en Informatique et
 *  en Automatique.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT
 * HOLDER> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* <stddef.h> -- common definitions (ISO C99 7.17) */

#ifndef _STDDEF_H

/* Glibc compatibility: if one of the __need_ macros is set,
   just define the corresponding type or macro
   and don't consider this file as fully included yet. */
#if !defined(__need_size_t) && !defined(__need_ptrdiff_t) && !defined(__need_wchar_t) && !defined(__need_NULL)
#define _STDDEF_H
#endif

#if defined(_STDDEF_H) || defined(__need_size_t)
#ifndef _SIZE_T
#define _SIZE_T
typedef unsigned long size_t;
#endif
#undef __need_size_t
#endif

#if defined(_STDDEF_H) || defined(__need_ptrdiff_t)
#ifndef _PTRDIFF_T
#define _PTRDIFF_T
typedef signed long ptrdiff_t;
#endif
#undef __need_ptrdiff_t
#endif

#if defined(_STDDEF_H) || defined(__need_wchar_t)
#ifndef _WCHAR_T
#define _WCHAR_T
#ifdef _WIN32
typedef unsigned short wchar_t;
#else
typedef signed int wchar_t;
#endif
#endif
#undef __need_wchar_t
#endif

#if defined(_STDDEF_H) || defined(__need_NULL)
#ifndef NULL
#define NULL 0
#endif
#undef __need_NULL
#endif

#if defined(_STDDEF_H) && !defined(offsetof)
#define offsetof(ty,member) ((size_t) &(((ty)*) NULL)->member)
#endif

#endif

