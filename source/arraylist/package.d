module arraylist;

import algorithm;
public import arraylist.exception;
import std.exception : assertThrown;
import std.range : ElementType, isInputRange;

/++
    A list-like wrapper for an array.
 +/
public class ArrayList(T)
{
    private
    {
        T[] _array;
        size_t _pointer = 0;

        @property @safe
        {
            size_t _capacity()
            {
                return this._array.length;
            }
        }

        @property @safe
        {
            size_t _freeCapacity()
            {
                return this._capacity - this.length;
            }
        }
    }

    public
    {
        /++
            Returns:
                The number of items stored in the list.
         +/
        @property @safe
        {
            size_t length()
            {
                return this._pointer;
            }
        }
        alias count = length;
    }

    /++
        Basic constructor.
     +/
    public this() @safe
    {
    }

    /++
        Params:
            initCapacity = initial capacity of the internal array
            initialItems = initial items for the new list
     +/
    public this(Range)(Range initialItems) @safe 
            if (isInputRange!Range && is(ElementType!Range == T))
    {
        this._array ~= initialItems[];
        this._pointer = this._array.length;
    }

    /++ ditto +/
    public this(size_t initCapacity) @safe
    {
        this._array = new T[](initCapacity);
    }

    /++ ditto +/
    public this(Range)(size_t initCapacity, Range initialItems) @safe 
            if (isInputRange!Range && is(ElementType!Range == T))
    {
        assert(initCapacity >= initialItems.length,
                "The initial capacity must be at least big enough to store the initial items.");

        this._array = new T[](initCapacity);
        initialItems.copyInto(this._array);

        this._pointer = initialItems.length;
    }

    public
    {
        /++
            Adds a new item to the list.
         +/
        void add(T item) @safe
        {
            this._pointer++;

            // filled to capacity?
            if (this._pointer >= this._capacity)
            {
                // yes: append
                this._array ~= item;
            }
            else
            {
                // no: copy
                this._array[this._pointer - 1] = item;
            }
        }

        /++
            Adds a range of items to the list.
         +/
        void add(Range)(Range r) @safe 
                if (isInputRange!Range && is(ElementType!Range == T))
        {
            // enough capacity for copy?
            if (r.length < (this._array.length - this._pointer))
            {
                this._array[this._pointer .. (this._pointer += r.length)] = r[];
            }
            else
            {
                const size_t fc = this._freeCapacity;

                // copy the first fc items to fill to capacity
                this._array[this._pointer .. $] = r[0 .. fc];

                // append remaining items
                this._array ~= r[fc .. $];

                this._pointer += r.length;
            }
        }

        /++
            Returns:
                The n-th item of the list.

            Throws:
                RangeError if index is out of range.
         +/
        T get(size_t n) @safe
        {
            if (n >= this.length)
                throw new IndexOutOfBoundsException(n, this.length);

            return this._array[n];
        }

        }

        /++
            Sets the value of the list's n-th item.
         +/
        void set(T value, size_t index) @safe
        {
            import core.Exception : RangeError;

            if (index >= this.length)
                throw new IndexOutOfBoundsException(index, this.length);

            this._array[index] = value;
        }

        /++
            Returns:
                A slice of the 
         +/
        T[] slice(size_t lower, size_t upper) @safe
        {
            assert(lower <= upper, "$lower must be less or equal $upper.");

            if (upper > this.length)
                throw new IndexOutOfBoundsException(upper, this.length);

            return this._array[lower .. upper];
        }

        /++
            Returns:
                A new array containing the same items as the list.
         +/
        T[] toArray() @safe
        {
            return this._array[0 .. this.length].dup;
        }
    }

    public
    {
        alias opCatAssign = add;
        alias opIndex = get;
        alias opIndexAssign = set;
    }
}

@safe unittest
{
    auto l = new ArrayList!int();

    l.add(122);
    l ~= 233;
    assert(l[0] == 122);
    assert(l[1] == 233);

    assert(l.length == 2);
}

@safe unittest
{
    auto l = new ArrayList!int(10);

    l.add(122);
    l ~= 233;
    assert(l[0] == 122);
    assert(l.get(1) == 233);

    assert(l.length == 2);

    assertThrown!IndexOutOfBoundsException(l[7]);
}

@safe unittest
{
    auto l = new ArrayList!int([122, 233, 344, 455]);
    assert(l.length == 4);

    l ~= 566;
    assert(l.length == 5);
    assert(l._array == [122, 233, 344, 455, 566]);
}

@safe unittest
{
    auto l = new ArrayList!int(10);

    l.add([0, 1, 2, 3]);
    l ~= [4, 5, 6, 7, 8, 9, 10];

    assert(l._array == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    l.add([11, 12]);
    assert(l._array == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
}

@safe unittest
{
    auto l = new ArrayList!int(10, [1, 2, 3]);
    assert(l.length == 3);

    l[0] = 0;
    l.set(-1, 1);
    assert(l._array[0 .. 3] == [0, -1, 3]);

    assertThrown!IndexOutOfBoundsException(l[5] = 0);
}
