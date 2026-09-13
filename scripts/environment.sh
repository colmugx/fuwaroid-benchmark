#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p results

{
  echo "timestamp_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "kernel: $(uname -a)"
  echo "cpu_model: $(lscpu | awk -F: '/Model name/{gsub(/^[ \t]+/,"",$2); print $2; exit}')"
  echo "logical_cpus: $(nproc)"
  echo "physical_cores: $(lscpu | awk -F: '/Core\(s\) per socket/{gsub(/ /,"",$2); c=$2} /Socket\(s\)/{gsub(/ /,"",$2); s=$2} END{if(c&&s) print c*s; else print "unknown"}')"
  echo "memory: $(free -h | awk '/Mem:/{print $2}')"
  echo "hyperfine: $(hyperfine --version | head -1)"
  echo "moon: $(moon version 2>&1 | head -1)"
  echo "fuwaroid_commit: $(git -C external/fuwaroid rev-parse HEAD)"
  echo "erlang_otp: $(erl -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt().' 2>/dev/null)"
  echo "java: $(java -version 2>&1 | head -1)"
  echo "akka_typed: 2.6.21"
  echo "caf: $(git -C build/caf-src/_deps/caf-src describe --tags --always 2>/dev/null || echo 1.1.0)"
  echo "ponyc: $(ponyc --version 2>&1 | head -1)"
  echo "go: $(go version)"
  echo "proto_actor_go: $(cd benchmarks/protoactor && go list -m -f '{{.Version}}' github.com/asynkron/protoactor-go)"
} > results/environment.txt

cat results/environment.txt
