
#ifndef ___ASYNCIO_TYPES_H__
#define ___ASYNCIO_TYPES_H__

/* Generation Date: 2026-11-19 06:19:10.344731+00:00 */
/* Newest Supported Python Version: 3.16 */

#ifdef __cplusplus
extern "C" {
#endif

#include <Python.h>

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 9)
    #define CPYTHON_ASYNCIO_39
#endif

#ifdef CPYTHON_ASYNCIO_39

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    fut_state fut_state;
    int fut_log_tb;
    int fut_log_blocking;
    PyObject* dict;
    PyObject* fut_weakreflist;
    _PyErr_StackItem fut_cancelled_exc_state;
} FutureObj;

#endif /* 3.9 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 10)
    #define CPYTHON_ASYNCIO_310
#endif

#ifdef CPYTHON_ASYNCIO_310

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    fut_state fut_state;
    int fut_log_tb;
    int fut_log_blocking;
    PyObject* dict;
    PyObject* fut_weakreflist;
    _PyErr_StackItem fut_cancelled_exc_state;
} FutureObj;

#endif /* 3.10 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 11)
    #define CPYTHON_ASYNCIO_311
#endif

#ifdef CPYTHON_ASYNCIO_311

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_context0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    fut_state fut_state;
    int fut_log_tb;
    int fut_blocking;
    PyObject* dict;
    PyObject* fut_weakreflist;
    PyObject* fut_cancelled_exc;
} FutureObj;

#endif /* 3.11 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 12)
    #define CPYTHON_ASYNCIO_312
#endif

#ifdef CPYTHON_ASYNCIO_312

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_context0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    fut_state fut_state;
    int fut_log_tb;
    int fut_blocking;
    PyObject* dict;
    PyObject* fut_weakreflist;
    PyObject* fut_cancelled_exc;
} FutureObj;

#endif /* 3.12 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 13)
    #define CPYTHON_ASYNCIO_313
#endif

#ifdef CPYTHON_ASYNCIO_313

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject *fut_loop;
    PyObject *fut_callback0;
    PyObject *fut_context0;
    PyObject *fut_callbacks;
    PyObject *fut_exception;
    PyObject *fut_exception_tb;
    PyObject *fut_result;
    PyObject *fut_source_tb;
    PyObject *fut_cancel_msg;
    PyObject *fut_cancelled_exc;
    fut_state fut_state;
    unsigned fut_log_tb: 1;
    unsigned fut_blocking: 1;
} FutureObj;

#endif /* 3.13 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 14)
    #define CPYTHON_ASYNCIO_314
#endif

#ifdef CPYTHON_ASYNCIO_314

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_context0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    PyObject* fut_cancelled_exc;
    PyObject* fut_awaited_by;
    fut_state fut_state;
    char fut_is_task;
    char fut_awaited_by_is_set;
    unsigned int fut_log_tb;
    unsigned int fut_blocking;
} FutureObj;

#endif /* 3.14 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 15)
    #define CPYTHON_ASYNCIO_315
#endif

#ifdef CPYTHON_ASYNCIO_315

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject *fut_loop;
    PyObject *fut_callback0;
    PyObject *fut_context0;
    PyObject *fut_callbacks;
    PyObject *fut_exception;
    PyObject *fut_exception_tb;
    PyObject *fut_result;
    PyObject *fut_source_tb;
    PyObject *fut_cancel_msg;
    PyObject *fut_cancelled_exc;
    PyObject *fut_awaited_by;
    fut_state fut_state;
    char fut_is_task;
    char fut_awaited_by_is_set;
    unsigned fut_log_tb: 1;
    unsigned fut_blocking: 1;
} FutureObj;

#endif /* 3.15 */

#if (PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION == 16)
    #define CPYTHON_ASYNCIO_316
#endif

#ifdef CPYTHON_ASYNCIO_316

/* enums */
typedef enum fut_state {
    STATE_PENDING = 0,
    STATE_CANCELLED = 1,
    STATE_FINISHED = 2,
} fut_state;

/* structs */
typedef struct FutureObj {
    PyObject_HEAD
    PyObject* fut_loop;
    PyObject* fut_callback0;
    PyObject* fut_context0;
    PyObject* fut_callbacks;
    PyObject* fut_exception;
    PyObject* fut_exception_tb;
    PyObject* fut_result;
    PyObject* fut_source_tb;
    PyObject* fut_cancel_msg;
    PyObject* fut_cancelled_exc;
    PyObject* fut_awaited_by;
    fut_state fut_state;
    char fut_is_task;
    char fut_awaited_by_is_set;
    unsigned int fut_log_tb;
    unsigned int fut_blocking;
} FutureObj;

#endif /* 3.16 */


#if(PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION < 9)
    #error "your version of python is not supported please upgrade to 3.9 or higher"
#endif

#if(PY_MAJOR_VERSION == 3 && PY_MINOR_VERSION > 16)
    #error "your version of python is not supported at the moment please throw an issue"
#endif

#ifdef __cplusplus
}
#endif /* __cplusplus */
#endif /* ___ASYNCIO_TYPES_H__ */
