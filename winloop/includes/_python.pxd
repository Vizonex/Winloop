cdef extern from "Python.h":

    unicode PyUnicode_FromString(const char *u)
    void* PyMem_RawMalloc(size_t n) nogil
    void* PyMem_RawRealloc(void *p, size_t n) nogil
    void* PyMem_RawCalloc(size_t nelem, size_t elsize) nogil
    void PyMem_RawFree(void *p) nogil

    void PyErr_SetInterrupt() nogil

    void _Py_RestoreSignals()

    object PyMemoryView_FromMemory(char *mem, ssize_t size, int flags)
    object PyMemoryView_FromObject(object obj)
    int PyMemoryView_Check(object obj)

    int PyContext_Enter(object)
    int PyContext_Exit(object)

    unicode PyUnicode_EncodeFSDefault(unicode)
    cdef enum:
        PyBUF_WRITE

    

cdef extern from "includes/context.h":
    object Context_CopyCurrent()
    int Context_Enter(object ctx)
    int Context_Exit(object ctx)
