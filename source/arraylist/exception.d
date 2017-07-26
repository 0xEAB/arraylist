module arraylist.exception;

import algorithm;
import std.conv : to;

/++
    Is thrown to indicate that an index is out of bounds/range.
 +/
@safe public class IndexOutOfBoundsException : Exception
{
    package this(string message, string file = __FILE__, size_t line = __LINE__)
    {
        super(message, file, line);
    }

    package this(size_t value, size_t lowerBound, size_t upperBound,
            string file = __FILE__, size_t line = __LINE__)
    {
        const string message = "Index " ~ value.to!string ~ " is out of bounds ("
            ~ lowerBound.to!string ~ " <= i < " ~ upperBound.to!string ~ ").";

        this(message, file, line);
    }

    package this(size_t value, size_t upperBound)
    {
        this(value, 0, upperBound);
    }

    @safe unittest
    {
        auto ex = new IndexOutOfBoundsException(12, 0, 10);
        assert(ex.file == __FILE__);
        assert(ex.line == __LINE__ - 2);
        assert(ex.msg.startsWith("Index 12"));
        assert(ex.msg.endsWith("(0 <= i < 10)."));
    }

    @safe unittest
    {
        auto ex = new IndexOutOfBoundsException("Oachkatzl...", "...schwoaf", 0x00EB);
        assert(ex.file == "...schwoaf");
        assert(ex.line == 0x00EB);
        assert(ex.msg == "Oachkatzl...");
    }
}
