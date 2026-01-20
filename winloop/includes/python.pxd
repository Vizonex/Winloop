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

    # Custom functions for making context.run faster.
    # meaning more speed for all handle calls being made
    object Context_RunNoArgs(object context, object method)
    object Context_RunOneArg(object context, object method, object arg)
    object Context_RunTwoArgs(object context, object method, object arg1, object arg2)


    void PyOS_BeforeFork()
    void PyOS_AfterFork_Parent()
    void PyOS_AfterFork_Child()

    void _Py_RestoreSignals()

    # TODO: Might consider our own version or duplicates
    # of _PyEval_EvalFrameDefault() so we can stop using noop._noop 
    # which has been the only problem with compiling with pyinstaller currently...
    # This way, no need for hooks!
