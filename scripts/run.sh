#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MESSAGES="${MESSAGES:-5000000}"
RUNS="${RUNS:-10}"
WARMUP="${WARMUP:-3}"
mkdir -p results

hyperfine \
  --warmup "$WARMUP" \
  --runs "$RUNS" \
  --export-json results/hyperfine.json \
  --command-name Fuwaroid \
    "external/fuwaroid/_build/native/release/build/bench/bench.exe tell messages=$MESSAGES warmup=0 note=cross-runtime >/dev/null" \
  --command-name ErlangOTP \
    "erl -noshell -pa build/erlang -eval 'bench:main($MESSAGES), halt().'" \
  --command-name AkkaTyped \
    "java -Xms512m -Xmx2g -jar build/akka/akka-bench.jar $MESSAGES" \
  --command-name CAF \
    "MESSAGES=$MESSAGES build/caf/caf_bench" \
  --command-name Pony \
    "build/pony/pony_bench $MESSAGES" \
  --command-name ProtoActorGo \
    "build/proto/proto_bench $MESSAGES"

python3 scripts/report.py \
  --input results/hyperfine.json \
  --messages "$MESSAGES" \
  --output results/report.md \
  --environment results/environment.txt

cat results/report.md
