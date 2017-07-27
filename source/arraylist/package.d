module arraylist;

import algorithm;
public import arraylist.exception;
import std.array : front, moveFront, popFront;
import std.exception : assertThrown;
import std.range : ElementType, ForwardAssignable, isInputRange, isNarrowString;

/++
    A list-like wrapper for an array.
 +/
public class ArrayList(T) : ForwardAssignable!T
{
    private
    {
        T[] _array;
        size_t _pointer = 0;

        @property @safe @nogc pure nothrow
        {
            size_t _capacity()
            {
                return this._array.length;
            }
        }

        @property @safe @nogc pure nothrow
        {
            size_t _freeCapacity()
            {
                return (this._capacity - this.length);
            }
        }
    }

    public
    {
        /++
            Returns:
                Does the list contain no items?
         +/
        @property @safe @nogc pure nothrow
        {
            bool empty()
            {
                return (this.length == 0);
            }
        }

        /++
            The list's first item.
         +/
        @property @safe @nogc pure nothrow
        {
            T front()
            {
                return this._array.front;
            }

            /++ ditto +/
            void front(T value)
            {
                this._array.front = value;
            }
        }

        /++ ditto +/
        alias first = front;

        /++
            The number of items stored in the list.
         +/
        @property @safe @nogc pure nothrow
        {
            size_t length()
            {
                return this._pointer;
            }
        }

        /++ ditto +/
        alias count = length;

        /++
            Saves the current state of the list to a new copy.
         +/
        @property @safe
        {
            ArrayList!T save()
            {
                return new ArrayList!T(this._capacity, this[0 .. $]);
            }
        }

        /++ ditto +/
        alias dup = save;
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

            See_Also:
                arraylist.ArrayList(T).insert
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
            Removes all items from the lists.

            See_Also:
                arraylist.ArrayList(T).purge
         +/
        void clear(size_t initCapacity = 0) @safe
        {
            this._pointer = 0;
            this._array = new T[](initCapacity);
        }

        /++
            Returns:
                Is the given item part of the list?
         +/
        bool contains(T item) @system
        {
            return this._array.contains(item);
        }

        /++
            Returns:
                Does the given range contain the same items as the list?
         +/
        bool equals(Range)(Range b) @safe 
                if (isInputRange!Range && is(ElementType!Range == T))
        {
            return (this[0 .. $] == b);
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

        /++
            Returns:
                The zero-based index of the given item.
                <0 if the given item is contained in the list.
         +/
        ptrdiff_t indexOf(T item) @system
        {
            return this._array.indexOf(item);
        }

        /++
            Inserts a new item into the last at the 

            See_Also:
                arraylist.ArrayList(T).add

         +/
        void insert(T item, size_t index) @safe
        {
            this._array ~= T.init;

            this._array[index .. ($ - 1)].dup.copyInto(this._array[(index + 1) .. $]);
            this._array[index] = item;

            this._pointer++;
        }

        /++
            Moves the front item of the list out and returns it,
            similar to a stack's pop method but affecting the front instead of a "peek".

            In comparison to std.range.primitives.moveFront
            this does not cause any harm.

            Returns:
                The popped front item

            See_Also:
                arraylist.ArrayList(T).popFront,
                https://www.tutorialspoint.com/data_structures_algorithms/stack_algorithm.htm
         +/
        T moveFront() @safe @nogc pure nothrow
        {
            T result = this._array.front;
            this.popFront();

            return result;
        }

        /++
            See_Also:
                std.range.interfaces.InputRange.opApply
         +/
        int opApply(scope int delegate(T) @safe dg) @safe
        {
            int result = 0;

            foreach (item; this[0 .. $])
            {
                result = dg(item);
                if (result)
                    return result;
            }

            return result;
        }

        /++ ditto +/
        int opApply(scope int delegate(size_t, T) @safe dg) @safe
        {
            int result = 0;

            foreach (idx, item; this[0 .. $])
            {
                result = dg(idx, item);
                if (result)
                    return result;
            }

            return result;
        }

        /++
            Moves the front item of the list out.

            See_Also:
                arraylist.ArrayList(T).moveFront
         +/
        void popFront() @safe @nogc pure nothrow
        {
            this._array.popFront();
            this._pointer--;
        }

        /++
            Removes all items from the lists.
            Preserves the internal capacity.

            See_Also:
                arraylist.ArrayList(T).clear
         +/
        void purge() @safe
        {
            this._pointer = 0;

            if (__traits(compiles, { T dummy = null; }))
                this._array[] = null;
        }

        /++
            Removes all occurrences of the given item from the list.
         +/
        void removeAllOf(T item) @system
        {
            this._array.removeAllOf(item);
            this._pointer = this._array.length;
        }

        /++
            Removes the n-th item from the list.
         +/
        void removeNth(size_t n) @safe
        {
            if (n >= this.length)
                throw new IndexOutOfBoundsException(n, this.length);

            this._array[(n + 1) .. $].copyInto(this._array[n .. $]);
            this._pointer--;
        }

        /++
            Sets the value of the list's n-th item.
         +/
        void set(T value, size_t index) @safe
        {
            if (index >= this.length)
                throw new IndexOutOfBoundsException(index, this.length);

            this._array[index] = value;
        }

        /++
            Returns:
                A slice of the 
         +/
        T[] slice(size_t lower = 0, size_t upper = opDollar) @safe
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
        T[] toArray() @safe pure nothrow
        {
            return this._array[0 .. this.length].dup;
        }
    }

    public
    {
        alias opCatAssign = add;
        alias opDollar = length;
        alias opEquals = equals;
        alias opIndex = get;
        alias opIndexAssign = set;
        alias opSlice = slice;
    }
}

@safe unittest
{
    auto l = new ArrayList!int();

    l.add(122);
    l ~= 233;
    assert(l[0] == 122);
    assert(l[1] == 233);

    assert(!l.empty);
    assert(l.length == 2);
}

@safe unittest
{
    auto l = new ArrayList!int(10);

    l.add(122);
    l ~= 233;
    assert(l[0] == 122);
    assert(l.get(1) == 233);

    assert(!l.empty);
    assert(l.length == 2);
    assert(l.front == 122);

    assertThrown!IndexOutOfBoundsException(l[7]);
}

@system unittest
{
    auto l = new ArrayList!int([122, 233, 344, 455]);
    assert(l.length == 4);

    l ~= 566;
    assert(l.length == 5);
    assert(l == [122, 233, 344, 455, 566]);

    assert(l.indexOf(233) == 1);
    assert(l.indexOf(899) < 0);

    l.insert(345, 3);
    assert(l.indexOf(345) == 3);
    assert(l == [122, 233, 344, 345, 455, 566]);
}

@system unittest
{
    auto l = new ArrayList!int(10);

    l.add([0, 1, 2, 3]);
    l ~= [4, 5, 6, 7, 8, 9, 10];

    assert(l._array == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    l.add([11, 12]);
    assert(l == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);

    l.removeNth(3);
    assertThrown!IndexOutOfBoundsException(l.removeNth(128));

    assert(!l.contains(3));
    assert(l[0 .. $] == [0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12]);

    assertThrown!IndexOutOfBoundsException(l[0 .. 128].dup);
}

@safe unittest
{
    auto l = new ArrayList!int(10, [1, 2, 3]);
    assert(l.length == 3);

    l[0] = 0;
    l.set(-1, 1);
    assert(l == [0, -1, 3]);

    assertThrown!IndexOutOfBoundsException(l[5] = 0);
}

@safe unittest
{
    auto l = new ArrayList!int();
    l.add([0, 1, 2, 3]);
    l.purge();

    assert(l.empty);
}

@system unittest
{
    class Foo
    {
    }

    auto l = new ArrayList!Foo();
    l.add([new Foo(), new Foo(), new Foo()]);

    assert(l.length == 3);

    l.purge();
    assert(l.length == 0);
    assert(l.empty);
    assert(l._array == [null, null, null]);

    l.clear(2);
    assert(l._array == [null, null]);

    auto f = new Foo();
    l.add(f);
    Foo[] ar = l.toArray();
    assert(ar == [f]);

    l.add(ar);
    assert(l == [f, f]);

    auto b = new Foo();
    l.add([f, null, f, b]);
    l.removeAllOf(f);
    assert(!l.contains(f));
    assert(l == [null, b]);
}

@system unittest
{
    import core.exception : AssertError;

    auto a = new ArrayList!int([1, 2, 3]);

    a.popFront();
    assert(a == [2, 3]);

    a.popFront();
    assert(a == [3]);

    a.front = 11;
    assert(a == [11]);

    assert(a.moveFront() == 11);
    assert(a.empty);

    assertThrown!AssertError(a.popFront());
}

@safe unittest
{
    auto l = new ArrayList!int([122, 233, 344, 455]);

    int[] c = [];
    foreach (item; l)
    {
        c ~= item;
    }
    assert(c == l);

    int f;
    foreach (item; l)
    {
        f = item;
        break;
    }
    assert(f == l.front);

    c = [];
    foreach (index, item; l)
    {
        assert(item == l[index]);
        c ~= item;
    }
    assert(c == l);

    f = -1;
    foreach (index, item; l)
    {
        f = item;
        break;
    }
    assert(f == l.front);
}

@safe unittest
{
    import std.range : isForwardRange;

    /++
        Inspired by:
            Andrei Alexandrescu:
                http://www.informit.com/articles/article.aspx?p=1407357&seqNum=7
     +/
    ptrdiff_t findAdjacent(Range)(Range range) if (isForwardRange!Range)
    {
        auto r = range.save();
        if (!r.empty())
        {
            auto s = r.save();
            s.popFront();

            for (ptrdiff_t i = 0; !s.empty(); i++)
            {
                if (r.front() == s.front())
                    return i;

                r.popFront();
                s.popFront();
            }
        }
        return -1;
    }

    immutable ptrdiff_t a1 = findAdjacent(new ArrayList!int([122, 233, 344, 344, 455]));
    assert(a1 == 2);

    assert(findAdjacent(new ArrayList!int([122, 233, 344, 455, 455])) == 3);
    assert(findAdjacent(new ArrayList!int([122, 233, 344, 455])) < 0);
}
