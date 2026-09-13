actor Counter
  let _main: Main tag
  var _count: U64 = 0

  new create(main: Main tag) =>
    _main = main

  be tick() =>
    _count = _count + 1

  be barrier() =>
    _main.done(_count)

actor Main
  let _env: Env
  let _expected: U64

  new create(env: Env) =>
    _env = env
    let n: USize =
      try
        env.args(1)?.usize()?
      else
        env.err.print("usage: pony_bench <messages>")
        env.exitcode(2)
        0
      end
    _expected = n.u64()

    let counter = Counter(this)
    var i: USize = 0
    while i < n do
      counter.tick()
      i = i + 1
    end
    counter.barrier()

  be done(count: U64) =>
    if count != _expected then
      _env.err.print(
        "count mismatch: want=" + _expected.string() + " got=" + count.string())
      _env.exitcode(1)
    end
