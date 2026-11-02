---
name: x-research
description: Free search and reading of X/Twitter posts and articles. Use when asked to check X/Twitter, find what people post about a topic, or read an x.com link.
---

# Searching and reading X for free

No API key is needed.

1. **Find posts:** use WebSearch (mode "extended") with `site:x.com` plus the topic, e.g.
   `site:x.com Claude Code Blender floor plan walkthrough`. Run 2–4 phrasings in the same turn.
   For a known author add their handle; for recent work add the month or year.
2. **Read each relevant post fully:** `~/.claude/bin/xread <x.com URL or post id>`.
   It prints JSON (author, date, text, links, media). If the post links to an X Article,
   it prints the whole article as Markdown with its image URLs instead.
3. **Images matter:** posts often carry the key content (prompts, settings, results) in images.
   Download them into a new empty folder and view them, e.g. as a contact sheet.
4. **Report honestly:** cite each post's URL. Search-engine coverage of X is partial, so say so.

Rules:
- If `xread` exits with an ERROR, X is unreachable: stop and report it, then work on getting access.
- Don't use Nitter or other scraping mirrors for search (X has sent takedown demands, and this
  environment's safety checks refuse it).
- Exhaustive or real-time search needs a paid API (xAI `x_search`, or the X API). Ask before using one.
