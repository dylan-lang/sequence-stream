module: sequence-stream


//
// Client reading methods
//


define method ext-peek
  (stream :: <sequence-stream>, #key on-end-of-stream = unsupplied())
=> (elem-or-eof :: <object>)
  check-stream-open(stream);
  check-stream-readable(stream);
  peek(stream, on-end-of-stream: on-end-of-stream)
end method;


define method ext-read-element
  (stream :: <sequence-stream>, #key on-end-of-stream = unsupplied())
=> (elem-or-eof :: <object>)
  check-stream-open(stream);
  check-stream-readable(stream);
  read-element(stream, on-end-of-stream: on-end-of-stream);
end method;


define method ext-unread-element
  (stream :: <sequence-stream>, elem :: <object>)
=> (elem :: <object>)
  check-stream-open(stream);
  check-stream-readable(stream);

  if (stream.stream-position ~= stream.stream-unread-from)
    cannot-unread-error(stream)
  end if;
  adjust-stream-position(stream, -1, grow: #f);
  stream.stream-storage[stream.stream-position + stream.stream-start]
end method;


define method ext-read
  (stream :: <sequence-stream>, n :: <integer>, #key on-end-of-stream = unsupplied())
=> (elements-or-eof :: <object>)
  check-stream-open(stream);
  check-stream-readable(stream);

  if (n = 0)
    #[]
  elseif (stream.stream-at-end?)
    case
      on-end-of-stream.supplied? => on-end-of-stream;
      otherwise => eos-error(stream);
    end case
  else
    let start-idx = stream.stream-start + stream.stream-position;
    let desired-end-idx = start-idx + n;
    let past-end-of-stream? = desired-end-idx > stream.stream-end;
    let end-idx = min(desired-end-idx, stream.stream-end);

    case
      ~past-end-of-stream? =>
        read-stream-elements(stream, start: start-idx, end: end-idx);
      on-end-of-stream.supplied? =>
        on-end-of-stream;
      otherwise =>
        let partial = read-stream-elements(stream, start: start-idx, end: end-idx);
        incomplete-error(stream, partial);
    end case
  end if
end method;


define method ext-read-into!
  (stream :: <sequence-stream>, n :: <integer>, coll :: <mutable-sequence>,
   #key start :: <integer> = 0, on-end-of-stream = unsupplied())
=> (count-or-eof :: <object>)
  check-stream-open(stream);
  check-stream-readable(stream);

  let (coll-start, coll-limit, coll-next, coll-done?, coll-key, coll-elem,
      coll-elem-setter) =
      forward-iteration-protocol(coll);

  // Skip to where we want to start inserting elements from the stream.
  let coll-start =
      for (coll-idx from 0 below start,
          coll-iter = coll-start then coll-next(coll, coll-iter),
          until: coll-done?(coll, coll-iter, coll-limit))
      finally
        coll-iter
      end for;

  // Start inserting elements from the stream and return results.
  let total-read = 0;
  block ()
    for (read-count from 0 below n,
        coll-iter = coll-start then coll-next(coll, coll-iter),
        until: coll-done?(coll, coll-iter, coll-limit))
      coll-elem-setter(read-element(stream), coll, coll-iter);
      total-read := read-count;
    end for;
    total-read
  exception (eos :: <end-of-stream-error>)
    case
      on-end-of-stream.supplied? =>
        on-end-of-stream;
      total-read = 0 =>
        error(eos);
      otherwise =>
        let partial = copy-sequence(coll, start: start, end: start + total-read);
        incomplete-error(stream, partial);
    end case
  end block;
end method;


define method ext-read-to
  (stream :: <sequence-stream>, to-elem :: <object>,
   #key on-end-of-stream = unsupplied(), test :: <function> = \==)
=> (elements-or-eof :: <object>, found? :: <boolean>)
  check-stream-open(stream);
  check-stream-readable(stream);
  read-through(stream, to-elem, keep-term: #f, test: test,
      on-end-of-stream: on-end-of-stream)
end method;


define method ext-read-through
  (stream :: <sequence-stream>, to-elem :: <object>,
   #key on-end-of-stream = unsupplied(), test :: <function> = \==)
=> (elements-or-eof :: <object>, found? :: <boolean>)
  check-stream-open(stream);
  check-stream-readable(stream);
  read-through(stream, to-elem, keep-term: #t, test: test,
      on-end-of-stream: on-end-of-stream)
end method;


define method ext-read-to-end (stream :: <sequence-stream>)
=> (elements :: <sequence>)
  check-stream-open(stream);
  check-stream-readable(stream);

  let start-idx = stream.stream-position + stream.stream-start;
  read-stream-elements(stream, start: start-idx, end: stream.stream-end)
end method;


define method ext-skip-through
  (stream :: <sequence-stream>, to-elem :: <object>, #key test :: <function> = \==)
=> (found? :: <boolean>)
  check-stream-open(stream);
  check-stream-readable(stream);
  skip-through(stream, to-elem, test: test).true?
end method;


define method ext-read-line
  (stream :: <string-stream>, #key on-end-of-stream = unsupplied())
=> (string-or-eof :: <object>, newline? :: <boolean>)
  check-stream-open(stream);
  check-stream-readable(stream);

  if (stream.stream-at-end?)
    case
      on-end-of-stream.supplied? => values(on-end-of-stream, #f);
      otherwise => eos-error(stream);
    end case
  else
    // Find line ending.
    let start-idx = stream.stream-position + stream.stream-start;
    let (found-idx, next-idx) = skip-through(stream, "\r\n", test: member?);
    let end-idx = found-idx | next-idx;
    let elements =
        copy-sequence(stream.stream-storage, start: start-idx, end: end-idx);

    // Skip over LF of CRLF.
    when (found? & peek(stream, on-end-of-stream: #f) = '\n')
      read-element(stream);
    end when;

    values(elements, found-idx.true?);
  end if;
end method;


define method ext-read-line-into!
  (stream :: <string-stream>, string :: <string>,
   #key start :: <integer> = 0, grow? :: <boolean> = #f,
      on-end-of-stream = unsupplied())
=> (string-or-eof :: <object>, newline? :: <boolean>)
  let (line, found?) = ext-read-line(stream.outer-stream, on-end-of-stream: #f);
  case
    line =>
      // Grow dest string if necessary.
      let size-needed = start + line.size;
      if (string.size < size-needed)
        if (grow?)
          let new-string = make(string.object-class, size: size-needed);
          string := replace-subsequence!(new-string, string, end: string.size);
        else
          error("String not large enough for input");
        end if;
      end if;

      // Copy into dest string. Would rather use replace-subsequence!, but
      // that doesn't guarantee that string itself is altered.
      for (i from start, c in line)
        string[i] := c;
      end for;

      values(string, found?);

    on-end-of-stream.supplied? =>
      values(on-end-of-stream, #f);

    otherwise =>
      eos-error(stream);
  end case;
end method;


define method ext-read-text
  (stream :: <string-stream>, n :: <integer>, #key on-end-of-stream = unsupplied())
=> (elements-or-eof :: <object>)
  let results = make(<string>, size: n);
  let read-count = ext-read-text-into!(stream.outer-stream, n, results,
                           on-end-of-stream: #f);
  case
    read-count =>
      if (read-count < results.size)
        copy-sequence(results, end: read-count)
      else
        results
      end if;
    on-end-of-stream.supplied? =>
      on-end-of-stream;
    otherwise =>
      eos-error(stream);
  end case;
end method;


define method ext-read-text-into!
  (stream :: <string-stream>, n :: <integer>, string :: <string>,
   #key start :: <integer> = 0, on-end-of-stream = unsupplied())
=> (count-or-eof :: <object>)
  check-stream-open(stream);
  check-stream-readable(stream);

  let total-read = 0;
  block ()
    for (i from start below min(start + n, string.size))
      let elem = read-element(stream);
      if (elem == '\r')
        elem := '\n';
        if (peek(stream, on-end-of-stream: #f) == '\n')
          read-element(stream);
        end if;
      end if;
      string[i] := elem;
      total-read := total-read + 1;
    end for;
    total-read
  exception (eos :: <end-of-stream-error>)
    case
      total-read > 0 =>
        total-read;
      on-end-of-stream.supplied? =>
        on-end-of-stream;
      otherwise =>
        error(eos);
    end case;
  end block;
end method;


//
// Client writing methods
//


define method ext-write-element
  (stream :: <sequence-stream>, elem :: <object>)
=> ()
  check-stream-open(stream);
  check-stream-writable(stream);
  check-element-type(stream, elem);

  if (stream.stream-at-end?)
    replace-stream-elements(stream, vector(elem));
  else
    let idx = stream.stream-start + stream.stream-position;
    stream.stream-storage[idx] := elem;
  end if;
  adjust-stream-position(stream, +1, grow: #f);
end method;


define method ext-write
  (stream :: <sequence-stream>, coll :: <sequence>,
   #key start: coll-start-idx :: <integer> = 0,
      end: coll-end-idx :: <integer> = coll.size)
=> ()
  check-stream-open(stream);
  check-stream-writable(stream);

  let (coll-start, coll-limit, coll-next, coll-done?, coll-key, coll-elem,
      coll-elem-setter) =
      forward-iteration-protocol(coll);

  // Skip to where we want to start taking elements from the collection.
  let coll-start =
      for (coll-idx from 0 below coll-start-idx,
          coll-iter = coll-start then coll-next(coll, coll-iter),
          until: coll-done?(coll, coll-iter, coll-limit))
      finally
        coll-iter
      end for;

  // Take elements from the collection and put them in the stream.
  let stream-start-idx = stream.stream-position + stream.stream-start;
  let (coll-start, coll-remainder-start-idx) =
      for (stream-idx from stream-start-idx below stream.stream-end,
          coll-idx from coll-start-idx below coll-end-idx,
          coll-iter = coll-start then coll-next(coll, coll-iter),
          until: coll-done?(coll, coll-iter, coll-limit))
        let elem = coll-elem(coll, coll-iter);
        check-element-type(stream, elem);
        stream.stream-storage[stream-idx] := elem;
      finally
        values(coll-iter, coll-idx);
      end for;

  // Deal with remainder that needs to be inserted. Check element types and
  // collect up a sequence to pass to 'replace-stream-elements'.
  let coll-remainder-size = coll-end-idx - coll-remainder-start-idx;
  if (coll-remainder-size > 0)
    let coll-remainder = make(<vector>, size: coll-remainder-size);
    for (remainder-idx from 0,
        coll-iter = coll-start then coll-next(coll, coll-iter),
        until: coll-done?(coll, coll-iter, coll-limit))
      let elem = coll-elem(coll, coll-iter);
      check-element-type(stream, elem);
      coll-remainder[remainder-idx] := elem;
    end for;
    replace-stream-elements(stream, coll-remainder);
  end if;

  // Reset stream position.
  adjust-stream-position(stream, coll-end-idx - coll-start-idx, grow: #f);
end method;


define method ext-write
  (stream :: <string-stream>, string :: <string>,
   #key start: string-start-idx :: <integer> = 0,
      end: string-end-idx :: <integer> = string.size)
=> ()
  check-stream-open(stream);
  check-stream-writable(stream);

  let string-span = string-end-idx - string-start-idx;
  if (string-span < string.size)
    string := copy-sequence(string, start: string-start-idx, end: string-end-idx);
  end if;

  let stream-start-idx = stream.stream-position + stream.stream-start;
  let stream-end-idx = stream-start-idx + string-span;
  replace-stream-elements(stream, string, start: stream-start-idx, end: stream-end-idx);
  adjust-stream-position(stream, string-span, grow: #f);
end method;


define sealed domain ext-write (<byte-string-stream>, <byte-string>);


define method ext-write-line
  (stream :: <sequence-stream>, string :: <string>,
   #key start: start-pos :: <integer> = 0,
      end: end-pos :: <integer> = string.size)
=> ()
  if (end-pos - start-pos < string.size)
    string := copy-sequence(string, start: start-pos, end: end-pos);
  end if;
  ext-write(stream.outer-stream, add(string, '\n'))
end method;


define method ext-new-line (stream :: <sequence-stream>) => ()
  ext-write-element(stream.outer-stream, '\n');
end method;

