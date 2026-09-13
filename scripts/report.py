#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

NAMES = [
    "Fuwaroid",
    "Erlang/OTP",
    "Akka Typed",
    "CAF",
    "Pony",
    "Proto.Actor Go",
]


def fmt_time(seconds: float) -> str:
    if seconds < 0.001:
        return f"{seconds * 1_000_000:.1f} µs"
    if seconds < 1:
        return f"{seconds * 1_000:.2f} ms"
    return f"{seconds:.3f} s"


def fmt_rate(value: float) -> str:
    if value >= 1_000_000:
        return f"{value / 1_000_000:.3f} M/s"
    if value >= 1_000:
        return f"{value / 1_000:.1f} k/s"
    return f"{value:.1f}/s"


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--messages", required=True, type=int)
    p.add_argument("--output", required=True)
    p.add_argument("--environment")
    args = p.parse_args()

    data = json.loads(Path(args.input).read_text())
    results = data.get("results", [])
    if len(results) != len(NAMES):
        raise SystemExit(f"expected {len(NAMES)} hyperfine results, got {len(results)}")

    rows = []
    for name, r in zip(NAMES, results):
        mean = float(r["mean"])
        stddev = float(r["stddev"])
        median = float(r["median"])
        minimum = float(r["min"])
        maximum = float(r["max"])
        throughput = args.messages / mean
        throughput_sigma = throughput * (stddev / mean) if mean else 0.0
        median_throughput = args.messages / median
        rows.append((name, mean, stddev, minimum, maximum, throughput, throughput_sigma, median_throughput))

    ranked = sorted(rows, key=lambda x: x[5], reverse=True)

    out = []
    out.append("# Cross-runtime actor benchmark\n")
    out.append(f"Workload: **{args.messages:,} asynchronous messages to one actor, followed by a completion barrier and exact count check.**\n")
    out.append("Measurement: `hyperfine`; each result is end-to-end process wall time. Runtime startup, JIT/warm-up inside the process, actor-system startup, message processing, barrier, and clean shutdown are therefore included.\n")
    out.append("This is a first-pass default-runtime comparison, **not** a controlled single-core mailbox-overhead benchmark.\n")
    out.append("| Rank | Runtime | Mean wall time ± σ | Min–Max | Throughput from mean ± propagated σ | Throughput from median |")
    out.append("|---:|---|---:|---:|---:|---:|")
    for idx, row in enumerate(ranked, 1):
        name, mean, stddev, minimum, maximum, throughput, sigma, median_throughput = row
        out.append(
            f"| {idx} | {name} | {fmt_time(mean)} ± {fmt_time(stddev)} | "
            f"{fmt_time(minimum)}–{fmt_time(maximum)} | {fmt_rate(throughput)} ± {fmt_rate(sigma)} | {fmt_rate(median_throughput)} |"
        )

    out.append("\n## Methodology notes\n")
    out.append("- All six implementations are built and executed in the **same GitHub Actions job on the same hosted runner**.")
    out.append("- The actor must process every submitted message before its barrier completes; a count mismatch fails the run.")
    out.append("- Implementations use their default scheduler/parallelism settings. This intentionally measures the shipped runtime configuration rather than equalized CPU resources.")
    out.append("- `hyperfine` warm-up repeats are whole-process warm-ups; JVM/BEAM processes are restarted for each measured sample.")
    out.append("- The throughput uncertainty is first-order propagation of hyperfine's wall-time standard deviation; it is descriptive noise, not a formal confidence interval.")
    out.append("- Akka Typed is pinned to 2.6.21 because newer Akka artifacts require Lightbend's tokenized secure repository; this keeps the public benchmark reproducible without secrets.")

    if args.environment:
        env_path = Path(args.environment)
        if env_path.exists():
            out.append("\n## Environment and exact versions\n")
            out.append("```text")
            out.append(env_path.read_text().rstrip())
            out.append("```")

    Path(args.output).write_text("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
