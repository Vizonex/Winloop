#ifndef __WINLOOP_COMPAT_H__
#define __WINLOOP_COMPAT_H__

#include <errno.h>
#include <stddef.h>
#include <signal.h>
#ifndef _WIN32
#include <sys/socket.h>
#include <sys/un.h>
#include <arpa/inet.h>
#include <unistd.h>
#else
#include <io.h>
#include <winsock2.h>
#endif
#include "Python.h"
#include "uv.h"


#ifndef EWOULDBLOCK
#define EWOULDBLOCK EAGAIN
#endif

#ifdef __APPLE__
#define PLATFORM_IS_APPLE 1
#else
#define PLATFORM_IS_APPLE 0
#endif


#ifdef __linux__
#  define PLATFORM_IS_LINUX 1
#  include <sys/epoll.h>
#else
#  define PLATFORM_IS_LINUX 0
#endif

#ifdef __APPLE__
#  define EPOLL_CTL_DEL 2
struct epoll_event {};
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event) {
    return 0;
};
#endif

#ifdef _WIN32
#  define EPOLL_CTL_DEL 2
/* error C2016: C requires that a struct or union have at least one member on Windows
with default compilation flags. Therefore put dummy field for now. */
struct epoll_event {int dummyfield;};
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event) {
    return 0;
};
#endif

#ifdef _WIN32
int SIGCHLD = 0;
int SO_REUSEPORT = 0;

struct sockaddr_un {unsigned short sun_family; char* sun_path;};

int socketpair(int domain, int type, int protocol, int socket_vector[2]) {
    return 0;
}

/* redefine write as counterpart of unistd.h/write */
int write(int fd, const void *buf, unsigned int count) {
    WSABUF wsa;
    unsigned long dbytes;
    wsa.buf = (char*)buf;
    wsa.len = (unsigned long)count;
    errno = WSASend(fd, &wsa, 1, &dbytes, 0, NULL, NULL);
    if (errno == SOCKET_ERROR) {
      errno = WSAGetLastError();
      if (errno == 10035)
        errno = EAGAIN;
      return -1;
    }
    else
      return dbytes;
}
#endif

PyObject *
MakeUnixSockPyAddr(struct sockaddr_un *addr)
{
#ifdef _WIN32
	return NULL;
#else
    if (addr->sun_family != AF_UNIX) {
        PyErr_SetString(
            PyExc_ValueError, "a UNIX socket addr was expected");
        return NULL;
    }

#ifdef __linux__
    int addrlen = sizeof (struct sockaddr_un);
    size_t linuxaddrlen = addrlen - offsetof(struct sockaddr_un, sun_path);
    if (linuxaddrlen > 0 && addr->sun_path[0] == 0) {
        return PyBytes_FromStringAndSize(addr->sun_path, linuxaddrlen);
    }
    else
#endif /* linux */
    {
        /* regular NULL-terminated string */
        return PyUnicode_DecodeFSDefault(addr->sun_path);
    }
#endif /* _WIN32 */
}

#ifdef _WIN32
#define PLATFORM_IS_WINDOWS 1
int getuid() {
	return 0;
}
#else
#define PLATFORM_IS_WINDOWS 0
#endif


/* TODO: (Vizonex) add static keyword to these functions */
#if PY_VERSION_HEX < 0x03070100

PyObject * Context_CopyCurrent(void) {
    return (PyObject *)PyContext_CopyCurrent();
};

int Context_Enter(PyObject *ctx) {
    return PyContext_Enter((PyContext *)ctx);
}

int Context_Exit(PyObject *ctx) {
    return PyContext_Exit((PyContext *)ctx);
}

#else

PyObject * Context_CopyCurrent(void) {
    return PyContext_CopyCurrent();
};

int Context_Enter(PyObject *ctx) {
    return PyContext_Enter(ctx);
}

int Context_Exit(PyObject *ctx) {
    return PyContext_Exit(ctx);
}

#endif


/* Originally apart of loop.pyx via calling context.run 
moved here so we can began optimizing more 
reason why something like this is more costly is because
we have to find the .run method if these were C Functions instead
This Call would no longer be needed and we skip right to the 
meat of the function (run) immediately however, we can go further 
to optimize that code too.

Before:
cdef inline run_in_context1(context, method, arg):
    Py_INCREF(method)
    try:
        return context.run(method, arg)
    finally:
        Py_DECREF(method)

After:
cdef inline run_in_context1(context, method, arg):
    Py_INCREF(method)
    try:
        return Context_RunNoArgs(context, method)
    finally:
        Py_DECREF(method)
*/

/* Context.run is literally this code right here referenced from python 3.15.1

static PyObject *
context_run(PyObject *self, PyObject *const *args,
            Py_ssize_t nargs, PyObject *kwnames)
{
    PyThreadState *ts = _PyThreadState_GET();

    if (nargs < 1) {
        _PyErr_SetString(ts, PyExc_TypeError,
                         "run() missing 1 required positional argument");
        return NULL;
    }

    if (_PyContext_Enter(ts, self)) {
        return NULL;
    }

    PyObject *call_result = _PyObject_VectorcallTstate(
        ts, args[0], args + 1, nargs - 1, kwnames);

    if (_PyContext_Exit(ts, self)) {
        Py_XDECREF(call_result);
        return NULL;
    }

    return call_result;
}

As we can see this code is not very expensive to maintain 
at all and can be simply reproduced and improved upon 
for our needs of being faster. 

Will name them after the different object calls made
to keep things less confusing. 
We also eliminate needing to 
find the run method in the ContextVar by doing so.
*/

static PyObject* Context_RunNoArgs(PyObject* context, PyObject* method){
    /* NOTE: Were looking for -1 but we can also say it's not 
    a no-zero value so we could even treat it as a true case... */
    if (Context_Enter(context)){
        return NULL;
    }

    #if PY_VERSION_HEX >= 0x030a0000
    PyObject* call_result = PyObject_CallNoArgs(method);
    #else 
    PyObject* call_result = PyObject_CallFunctionObjArgs(method, NULL);
    #endif

    if (Context_Exit(context)){
        Py_XDECREF(call_result);
        return NULL;
    }

    return call_result;
}

static PyObject* Context_RunOneArg(PyObject* context, PyObject* method, PyObject* arg){
    if (Context_Enter(context)){
        return NULL;
    }
    /* Introduced in 3.9 */
    /* NOTE: Kept around backwards compatability since the same features are planned for uvloop */
    #if PY_VERSION_HEX >= 0x03090000
        PyObject* call_result = PyObject_CallOneArg(method, arg);
    #else /* verison < 3.9 */
        PyObject* call_result = PyObject_CallFunctionObjArgs(method, arg, NULL);
    #endif
    if (Context_Exit(context)){
        Py_XDECREF(call_result);
        return NULL;
    }
    return call_result;
}

static PyObject* Context_RunTwoArgs(PyObject* context, PyObject* method, PyObject* arg1, PyObject* arg2){
    /* Cython can't really do this PyObject array packing so writing this in C 
    has a really good advantage */
    if (Context_Enter(context)){
        return NULL;
    }
    #if PY_VERSION_HEX >= 0x03090000
    /* begin packing for call... */    
    PyObject* args[2];
    args[0] = arg1;
    args[1] = arg2;
    PyObject* call_result = PyObject_Vectorcall(method, args, 2, NULL);
    #else 
    PyObject* call_result = PyObject_CallFunctionObjArgs(method, arg1, arg2, NULL);    
    #endif 
    if (Context_Exit(context)){
        Py_XDECREF(call_result);
        return NULL;
    }
    return call_result;
}


/* inlined from cpython/Modules/signalmodule.c
 * https://github.com/python/cpython/blob/v3.13.0a6/Modules/signalmodule.c#L1931-L1951
 * private _Py_RestoreSignals has been moved to CPython internals in Python 3.13
 * https://github.com/python/cpython/pull/106400 */

void
_Py_RestoreSignals(void)
{
#ifdef SIGPIPE
    PyOS_setsig(SIGPIPE, SIG_DFL);
#endif
#ifdef SIGXFZ
    PyOS_setsig(SIGXFZ, SIG_DFL);
#endif
#ifdef SIGXFSZ
    PyOS_setsig(SIGXFSZ, SIG_DFL);
#endif
}

#ifdef _WIN32
void PyOS_BeforeFork() {
    return;
}	
void PyOS_AfterFork_Parent() {
    return;
}
void PyOS_AfterFork_Child() {
    return;
}

#endif

// TODO: all versions of _PyEval_EvalFrameDefault so we can get rid of _noop.noop
// which would be a massive performance enhancement and allow pyinstaller to compile 3.9 -> 3.14

// PyObject* PerfomNoop(){
//     PyEval_EvalCode()
// }


#endif // __WINLOOP_COMPAT_H__