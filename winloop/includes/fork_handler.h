volatile uint64_t MAIN_THREAD_ID = 0;
volatile int8_t MAIN_THREAD_ID_SET = 0;

HANDLE CreateHandle(){
    return CreateEventW(NULL, TRUE, FALSE, NULL);
}

void setMainThreadID(uint64_t id) {
    MAIN_THREAD_ID = id;
    MAIN_THREAD_ID_SET = 1;
}
