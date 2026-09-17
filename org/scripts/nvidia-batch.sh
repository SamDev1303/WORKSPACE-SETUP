#!/bin/bash
# nvidia-batch.sh — Batch inference via NVIDIA NIM API
# Usage: nvidia-batch.sh "<topic>" <mode> [model]
# Modes: social, email, review, extract, summarize

set -euo pipefail
set -a
_env="${KODA_ENGINE:-$HOME/claudeking.cloud}/.env"; [ -f "$_env" ] || { echo "nvidia-batch: $_env missing (NVIDIA_API_KEY lives there)" >&2; exit 2; }; source "$_env"
set +a

TOPIC="$1"
MODE="${2:-social}"
MODEL="${3:-meta/llama-3.3-70b-instruct}"
OUTDIR="${KODA_ENGINE:-$HOME/claudeking.cloud}/claudeking/nvidia-output"
mkdir -p "$OUTDIR"

nvidia_call() {
  local prompt="$1"
  local model="${2:-$MODEL}"
  local max_tokens="${3:-500}"

  export NB_MODEL="$model" NB_PROMPT="$prompt" NB_MAX_TOKENS="$max_tokens"   # 2026-09-18: values reach python via env, never interpolated into code
  python3 -c "
import json, os, urllib.request, os

payload = json.dumps({
    'model': os.environ['NB_MODEL'],
    'messages': [{'role': 'user', 'content': os.environ['NB_PROMPT']}],
    'max_tokens': int(os.environ['NB_MAX_TOKENS']),
    'temperature': 0.7
}).encode()

req = urllib.request.Request(
    'https://integrate.api.nvidia.com/v1/chat/completions',
    data=payload,
    headers={
        'Authorization': 'Bearer ' + os.environ['NVIDIA_API_KEY'],
        'Content-Type': 'application/json'
    }
)

try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read())
        print(data['choices'][0]['message']['content'])
except Exception as e:
    print(f'ERROR: {e}')
"
}

case "$MODE" in
  social)
    echo "Generating social copy for: $TOPIC"
    echo "---"

    echo "=== X (Twitter) ==="
    nvidia_call "Write a punchy tweet (max 280 chars) about: $TOPIC. Tech/AI audience. No hashtags in body, add 2-3 at the end. Be opinionated." | tee "$OUTDIR/social-x.txt"

    echo -e "\n=== LinkedIn ==="
    nvidia_call "Write a LinkedIn post (150-300 words) about: $TOPIC. Audience: SMB business owners aged 35-60 in Australia/US. Lead with business outcome, plain English, no jargon. End with a specific question. No hashtags." "mistralai/mistral-large-3-675b-instruct-2512" | tee "$OUTDIR/social-linkedin.txt"

    echo -e "\n=== Instagram ==="
    nvidia_call "Write an Instagram caption (2-4 lines + 8-12 hashtags) about: $TOPIC. Engaging, visual-first mindset. Include a call to action." | tee "$OUTDIR/social-ig.txt"

    echo -e "\n=== Facebook ==="
    nvidia_call "Write a Facebook post about: $TOPIC. Conversational, personal story voice. What we are building, not tool explanations. 3-5 sentences." | tee "$OUTDIR/social-fb.txt"

    echo -e "\nAll drafts saved to $OUTDIR/social-*.txt"
    ;;

  email)
    echo "Generating email draft for: $TOPIC"
    nvidia_call "Write a cold outreach email about: $TOPIC. Target: small business owner or director in Australia. Professional but warm. Include: subject line, greeting, 3-sentence pitch focusing on business outcome, clear CTA, sign-off as Sam from ClaudeKing. Keep under 150 words." "mistralai/mistral-large-3-675b-instruct-2512" 600 | tee "$OUTDIR/email-draft.txt"
    echo -e "\nSaved to $OUTDIR/email-draft.txt"
    ;;

  review)
    echo "Generating code review for: $TOPIC"
    nvidia_call "Review this code for bugs, security issues, and improvements. Be concise, list only real issues: $TOPIC" "qwen/qwen3-coder-480b-a35b-instruct" 800 | tee "$OUTDIR/code-review.txt"
    echo -e "\nSaved to $OUTDIR/code-review.txt"
    ;;

  extract)
    echo "Extracting structured data from: $TOPIC"
    nvidia_call "Extract key information from this text and return as JSON with relevant fields: $TOPIC" | tee "$OUTDIR/extracted.json"
    echo -e "\nSaved to $OUTDIR/extracted.json"
    ;;

  summarize)
    echo "Summarizing: $TOPIC"
    nvidia_call "Summarize this in 3 bullet points, focusing on actionable insights: $TOPIC" "meta/llama-4-maverick-17b-128e-instruct" 300 | tee "$OUTDIR/summary.txt"
    echo -e "\nSaved to $OUTDIR/summary.txt"
    ;;

  *)
    echo "Unknown mode: $MODE"
    echo "Available: social, email, review, extract, summarize"
    exit 1
    ;;
esac
