#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$PROJECT_ROOT/_site"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

cp "$SCRIPT_DIR/index.html" "$OUT_DIR/"
cp "$SCRIPT_DIR/style.css" "$OUT_DIR/"

if [ -f "$SCRIPT_DIR/screenshot.png" ]; then
  cp "$SCRIPT_DIR/screenshot.png" "$OUT_DIR/"
fi

TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

npx --yes marked -i "$PROJECT_ROOT/README.md" --gfm -o "$TMPFILE"

node -e "
  const fs = require('fs');
  const tpl = fs.readFileSync('$SCRIPT_DIR/docs.html', 'utf8');
  let body = fs.readFileSync('$TMPFILE', 'utf8');
  body = body.replace(/<(h[1-6])>(.*?)<\/h[1-6]>/g, (m, tag, text) => {
    const id = text.replace(/<[^>]+>/g, '').toLowerCase()
      .replace(/[^\w\s-]/g, '').replace(/\s+/g, '-').replace(/-+$/, '');
    return '<' + tag + ' id=\"' + id + '\">' + text + '</' + tag + '>';
  });
  fs.writeFileSync('$OUT_DIR/docs.html', tpl.replace('<!-- README_CONTENT -->', body));
"

echo "Site built at $OUT_DIR"
