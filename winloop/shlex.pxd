

# TODO: In the future I would like to see this module start using 
# const char* and other simillar optimizations, will start with 
# this for now - Vizonex

cdef class shlex:
    cdef:
        readonly str commenters
        readonly str wordchars
        readonly str whitespace
        readonly str escape
        readonly str quotes
        readonly str escapedquotes
        readonly bint whitespace_split
        readonly str infile
        readonly object instream 
        readonly str source
        readonly int debug
        readonly int lineno
        readonly str token
        readonly str eof
        readonly bint posix
        object _punctuation_chars
        object state
        object pushback
        object filestack
    
    cpdef object get_token(self)
    cpdef object push_token(self, object tok)
    cpdef object read_token(self)
    cpdef tuple sourcehook(self, str newfile)
    cpdef object push_source(self, object newstream, object newfile=*)
    cpdef object pop_source(self)
    cpdef object error_leader(self, object infile=*, object lineno=*)
 
    # Custom function used for saving time with splitting data up.
    cpdef list split(self, str s)
