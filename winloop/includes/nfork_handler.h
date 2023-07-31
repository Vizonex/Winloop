#ifndef _NON_FORK_HANDLER_H_
#define _NON_FORK_HANDLER_H_

/* I call it NON-Fork Because We unfortunately can't fork in windows - Vizonex */

#include <stdint.h>
#include <errno.h>


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