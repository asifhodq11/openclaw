---
name: web-search
description: "Search the web for current information, news, prices, or anything beyond your training data. Use when: user asks about recent events, 'what is X', 'latest news on Y', current prices, or anything time-sensitive."
metadata: { "openclaw": { "emoji": "🔍", "requires": { "bins": ["curl"] } } }
---
	
# Web Search
	
Search DuckDuckGo for current information. No API key required.
	
## Search
```bash
curl -sL "https://ddg-webapp-aagd.vercel.app/search?q=QUERY&max_results=5" \
  -H "Accept: application/json"
```
	
## Instant answers (facts, calculations, conversions)
```bash
curl -sL "https://api.duckduckgo.com/?q=QUERY&format=json&no_redirect=1&skip_disambig=1" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('AbstractText') or d.get('Answer') or 'No instant answer')"
```
	
Replace QUERY with URL-encoded search terms.
Summarize results in your own words. Never dump raw JSON to the user.
For news queries, include "site:reuters.com OR site:bbc.com" for reliable sources.
