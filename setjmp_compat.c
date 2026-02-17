// Compatibility shim for MSVCRT-compiled static libraries on UCRT MinGW.
// The bundled .a files reference __imp__setjmp (msvcrt.dll IAT entry)
// with 1-arg signature. UCRT's _setjmp takes 2 args (jmp_buf, void*).
// This wrapper bridges the gap.
#if defined(_WIN64)
#include <setjmp.h>

#ifdef _UCRT
static int __cdecl _setjmp_1arg(jmp_buf buf) {
    return _setjmp(buf, NULL);
}

int (__cdecl *__imp__setjmp)(jmp_buf) = _setjmp_1arg;
#endif
#endif
