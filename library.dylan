module: dylan-user
author: Dustin Voss


define library sequence-stream
  use common-dylan;
  use io, import: { streams };

  export sequence-stream;
end library;


define module sequence-stream
  // from common-dylan
  use dylan;
  use common-extensions;
  // from io
  use streams, prefix: "ext-";
  use streams,
    import: { <stream>, <basic-stream>, <positionable-stream>, <stream-error>,
              <stream-closed-error>, <end-of-stream-error>, <stream-not-readable>,
              <stream-not-writable>, <incomplete-read-error>, <byte-character>,
              outer-stream };

  export <sequence-stream>, <string-stream>, <byte-string-stream>;
end module;
