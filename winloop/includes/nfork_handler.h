#ifndef _NON_FORK_HANDLER_H_
#define _NON_FORK_HANDLER_H_


#include <stdint.h>
#include <errno.h>
// #include <uv.h>

volatile uint64_t MAIN_THREAD_ID = 0;
volatile int8_t MAIN_THREAD_ID_SET = 0;



void setMainThreadID(uint64_t id) {
    MAIN_THREAD_ID = id;
    MAIN_THREAD_ID_SET = 1;
}


HANDLE CreateHandle(){
    return CreateEventW(NULL, TRUE, FALSE, NULL);
}

#endif /* _NON_FORK_HANDLER_H_ */