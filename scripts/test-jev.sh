#!/usr/bin/env bash
# Live regression check for bin/jev. Calls the TypeSafe API (needs TYPESAFE_API_KEY
# or ~/.config/typesafe/env); costs well under a cent per run.
#   bash scripts/test-jev.sh
set -euo pipefail
jev="$(cd "$(dirname "$0")/.." && pwd)/bin/jev"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
fail=0
expect() {  # expect <label> <jq predicate> <jev args...>
  local label=$1 pred=$2 out; shift 2
  out=$("$jev" "$@")
  if jq -e "$pred" <<<"$out" >/dev/null; then echo "ok   $label"; else echo "FAIL $label: $out"; fail=1; fi
}

# Recorded pplx-agent failure (2026-08-15): it said 0.08% / 25th, FIRST.org said 0.91% / 57th.
cat >"$t/epss.txt" <<'EOF'
Exploit Prediction Scoring System (EPSS) - FIRST.org
CVE-2026-32871
Date: 2026-08-15
EPSS score: 0.91% (probability of exploitation activity in the next 30 days)
Percentile: 57th - this CVE scores higher than 57% of all scored vulnerabilities.
EOF
expect "wrong figure -> contradicted" '.verdict=="contradicted" and .numbers_missing==["0.08%","25"]' \
  check "CVE-2026-32871 has an EPSS score of 0.08%, in the 25th percentile." "$t/epss.txt"
expect "right figure -> verified" '.verdict=="verified" and .numbers_missing==[]' \
  check "CVE-2026-32871 has an EPSS score of 0.91%, in the 57th percentile." "$t/epss.txt"
expect "missing quote -> fabricated" '.verdict=="fabricated" and .confidence==null' \
  check "EPSS is 0.08%" "$t/epss.txt" --quote "EPSS score: 0.08%"
expect "off-topic claim -> unsupported" '.verdict=="unsupported"' \
  check "CVE-2026-32871 has a public proof-of-concept exploit." "$t/epss.txt"

# Number matching is whole-number: "25" must not hit "2025", "0.08%" must not hit "10.08%".
echo 'Report published 2025. Scores rose 10.08% this year.' >"$t/boundary.txt"
expect "number boundaries" '.numbers_missing==["0.08%","25"]' \
  check "The score is 0.08%, 25th percentile." "$t/boundary.txt"

# Quote found -> only a window around it is sent (TypeSafe citation-check cookbook case).
cat >"$t/rfc.txt" <<'EOF'
4.1.4.  "exp" (Expiration Time) Claim

   The "exp" (expiration time) claim identifies the expiration time on
   or after which the JWT MUST NOT be accepted for processing.  The
   processing of the "exp" claim requires that the current date/time
   MUST be before the expiration date/time listed in the "exp" claim.
   Implementers MAY provide for some small leeway, usually no more than
   a few minutes, to account for clock skew.  Its value MUST be a number
   containing a NumericDate value.  Use of this claim is OPTIONAL.
EOF
expect "quote window -> contradicted" '.verdict=="contradicted" and .context=="quote_found"' \
  check 'The "exp" claim is required in every JWT.' "$t/rfc.txt" \
  --quote 'The “exp” (expiration time) claim identifies the expiration time on or after which the JWT MUST NOT be accepted for processing.'

# rank reorders: the on-topic hit must come first.
printf '%s\n' \
  "https://example.com/cats | Cat care | How often to feed a kitten" \
  "https://docs.typesafe.ai/models | Models | Jev 1.13 price \$0.042 per Mtok input; 100K tokens/s rate limit" \
  >"$t/hits.txt"
top=$("$jev" rank "What does TypeSafe charge per token for Jev?" <"$t/hits.txt" | head -1)
case $top in *docs.typesafe.ai*) echo "ok   rank order" ;; *) echo "FAIL rank order: $top"; fail=1 ;; esac

exit $fail
