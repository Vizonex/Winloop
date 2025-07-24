from cpython.object cimport PyObject


cdef extern from "Python.h":
    int PY_VERSION_HEX

    unicode PyUnicode_FromString(const char *)

    void* PyMem_RawMalloc(size_t n) nogil
    void* PyMem_RawRealloc(void *p, size_t n) nogil
    void* PyMem_RawCalloc(size_t nelem, size_t elsize) nogil
    void PyMem_RawFree(void *p) nogil

    object PyUnicode_EncodeFSDefault(object)
    void PyErr_SetInterrupt() nogil

    object PyMemoryView_FromMemory(char *mem, ssize_t size, int flags)
    object PyMemoryView_FromObject(object obj)
    int PyMemoryView_Check(object obj)

    cdef enum:
        PyBUF_WRITE
    # This is For noop._noop to optimize the time calling it
    PyObject* PyObject_CallNoArgs(object func)




cdef extern from "includes/compat.h":
    object Context_CopyCurrent()
    int Context_Enter(object) except -1
    int Context_Exit(object) except -1

    void PyOS_BeforeFork()
    void PyOS_AfterFork_Parent()
    void PyOS_AfterFork_Child()

    void _Py_RestoreSignals()

    # TODO: Might consider our own version or duplicates
    # of _PyEval_EvalFrameDefault() so we can stop using noop._noop 
    # which has been the only problem with compiling with pyinstaller currently...
    # This way, no need for hooks!
