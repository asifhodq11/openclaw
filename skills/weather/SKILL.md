---
name: weather
description: "Get current weather and forecasts for any city. No API key needed. Use when: user asks about weather, temperature, rain, wind, or forecasts."
metadata: { "openclaw": { "emoji": "🌤️", "requires": { "bins": ["curl"] } } }
---
	
# Weather
	
Use wttr.in to answer weather questions. No API key required.
	
## Current conditions
```bash
curl -s "wttr.in/CITY?format=%l:+%c+%t+(feels+%f),+%w+wind,+%h+humidity"
```
	
## 3-day forecast
```bash
curl -s "wttr.in/CITY?format=v2"
```
	
## Rain today?
```bash
curl -s "wttr.in/CITY?format=%l:+%c+%p+precipitation"
```
	
Replace CITY with the user's location. Use airport codes for precision (e.g. JFK, LHR).
Always include location in the query — never guess it.
