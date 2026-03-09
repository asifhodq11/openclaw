---
name: note-memory
description: "Save, retrieve, and list personal notes that persist across sessions. Use when: user says 'remember this', 'save a note', 'what did I save about X', 'list my notes', or 'forget X'."
metadata: { "openclaw": { "emoji": "📝" } }
---
	
# Note Memory
	
Save notes to the workspace so they persist across sessions and redeploys.
	
Notes are stored as plain text files in `$WORKSPACE/notes/`.
	
## Save a note
```bash
mkdir -p "$OPENCLAW_WORKSPACE_DIR/notes"
echo "CONTENT" > "$OPENCLAW_WORKSPACE_DIR/notes/SLUG.txt"
echo "Saved."
```
	
## Read a note
```bash
cat "$OPENCLAW_WORKSPACE_DIR/notes/SLUG.txt" 2>/dev/null || echo "Note not found."
```
	
## List all notes
```bash
ls "$OPENCLAW_WORKSPACE_DIR/notes/" 2>/dev/null | sed 's/\.txt$//' || echo "No notes saved yet."
```
	
## Delete a note
```bash
rm -f "$OPENCLAW_WORKSPACE_DIR/notes/SLUG.txt" && echo "Deleted." || echo "Not found."
```
	
Use a short, lowercase, hyphenated SLUG based on the topic (e.g. `shopping-list`, `project-ideas`).
Never expose the file path to the user — just confirm the action.
