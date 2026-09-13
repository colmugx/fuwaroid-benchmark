# fuwaroid-benchmark

Public, reproducible cross-runtime actor benchmarks for Fuwaroid and established actor implementations.

The primary goal is not to prove that Fuwaroid is the fastest implementation. The goal is to run recognizable actor systems on the **same GitHub Actions runner**, preserve raw evidence, and make the methodology inspectable.

## Current field

The first suite compares:

- Fuwaroid (MoonBit, built from `colmugx/fuwaroid` `main`)
- Erlang/OTP `gen_server` (OTP 29.0.6)
- Akka Typed (2.6.21)
- CAF / C++ Actor Framework (1.1.0)
- Pony (current Pony release installed by `ponyup`)
- Proto.Actor Go (0.4.0)

Akka deserves one qualification: current Akka 2.10 artifacts are distributed through Lightbend's tokenized secure repository. This benchmark intentionally uses **Akka Typed 2.6.21**, the last widely reproducible Maven Central line, so the public workflow needs no private credentials. The generated report records this explicitly.

## v1 workload: single-actor tell throughput

Every adapter implements the same shape:

1. create one actor with an integer counter;
2. asynchronously submit `N` tiny messages;
3. submit a barrier/request after those messages;
4. wait for the barrier result;
5. fail unless the actor reports exactly `N` processed messages;
6. shut down cleanly.

This avoids a common invalid benchmark where the producer finishes quickly but the actor still has a mailbox full of unprocessed work.

Fuwaroid is cloned and compiled exactly as a consumer would build the benchmark executable:

```bash
moon update
moon build --target native --release
```

The expected binary is:

```text
_build/native/release/build/bench/bench.exe
```

## Measurement

The Linux runner uses [`hyperfine`](https://github.com/sharkdp/hyperfine) for repeated process-level measurements. `hyperfine` reports mean wall time, standard deviation, median, min, and max and exports the raw samples as JSON.

On pushes to `main`, the default campaign is:

```text
messages: 5,000,000
measured runs: 10
whole-process warm-up runs: 3
```

The generated Markdown report includes:

- `mean wall time ± standard deviation`;
- min/max wall time;
- throughput derived from the mean;
- first-order propagated throughput standard deviation;
- throughput derived from the median;
- exact runner CPU, memory, kernel, toolchain versions, and Fuwaroid commit.

### Important limitation

This first suite is intentionally a **default-runtime, end-to-end process benchmark**. Process startup, JVM/BEAM initialization, JIT work performed during the process, actor-system startup, message processing, the completion barrier, and shutdown are all inside the measured wall time.

It is therefore **not** yet a controlled measurement of pure mailbox dispatch cost. It also does not force every runtime to one CPU. A later suite should add a single-CPU track (`taskset`, BEAM schedulers, Akka dispatcher parallelism, CAF worker count, Pony scheduler count, and Go `GOMAXPROCS`) and request/reply latency workloads.

## CI behavior

`push` to `main` runs the full benchmark. Pull requests run a smaller smoke campaign so adapter/build failures can be fixed before merging. A manual dispatch can override message count and repetitions.

All six implementations are built and measured inside **one job**, so they share one hosted runner rather than being spread over unrelated VMs.

Artifacts retain:

```text
results/hyperfine.json
results/environment.txt
results/report.md
```

The report is also appended to the GitHub Actions step summary.

## Local entry points

With the required toolchains installed:

```bash
bash scripts/build.sh
bash scripts/environment.sh
MESSAGES=5000000 RUNS=10 WARMUP=3 bash scripts/run.sh
```

Do not compare a local result against a GitHub-hosted result as if the hardware were controlled. The public comparison is the set of implementations from the same workflow run.
