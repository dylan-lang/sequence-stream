A replacement for the Open Dylan `\<sequence-stream\>
<https://opendylan.org/library-reference/io/streams.html#io:streams:[sequence-stream]>`_
classes.

This module is motivated by various issues with ``<sequence-stream>`` in Open
Dylan's IO library. It provides implementations for stream methods that act as
described in the Open Dylan `Streams Module
<https://opendylan.org/library-reference/io/streams.html>`_ documentation.

If possible, these classes use the ``contents:`` initialization argument as the
backing store; if not, they use a copy. The backing store will be a general
instance of ``<vector>`` and will be a ``<stretchy-vector>`` if and only if the
stream is writable. This differs from the normal ``<sequence-stream>`` class,
in which using a ``<stretchy-vector>`` as the ``contents:`` initialization
argument guarantees that all changes to the ``<stretchy-vector>`` are reflected
in the ``<sequence-stream>`` and vice versa.

When a writable ``<sequence-stream>`` grows its backing store, it uses the
filler element specified by the ``fill:`` initialization argument.

This class supports a ``position-offset:`` initialization argument that sets
the effective stream position at the first element of the stream. This allows
sequence streams to act as a subset of another, larger stream. The
initialization argument defaults to ``0``.
