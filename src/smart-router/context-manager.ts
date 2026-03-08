import type { TaskTier } from './classifier.js';

// Token budget limits per tier
const BUDGETS: Record<TaskTier, number> = {
  simple:  8_000,
  medium:  32_000,
  complex: 80_000,
};

// Rough token estimator (1 token ≈ 4 chars)
export function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4);
}

export interface ContextBlock {
  type: 'system_core' | 'current_message' | 'recent_conversation' |
        'relevant_memory' | 'active_tools' | 'workspace_summary' |
        'workspace_files' | 'full_history';
  content: string;
  priority: number; // lower = kept first when trimming
}

// Priority order: lower number = never drop first
const PRIORITY_MAP: Record<ContextBlock['type'], number> = {
  system_core:           1, // never dropped
  current_message:       2, // never dropped
  recent_conversation:   3,
  relevant_memory:       4,
  active_tools:          5,
  workspace_summary:     6,
  workspace_files:       7,
  full_history:          8, // dropped first
};

export function enforceContextBudget(
  blocks: ContextBlock[],
  tier: TaskTier
): ContextBlock[] {
  const budget = BUDGETS[tier];
  const sorted = [...blocks].sort((a, b) => a.priority - b.priority);

  let totalTokens = 0;
  const kept: ContextBlock[] = [];

  for (const block of sorted) {
    const tokens = estimateTokens(block.content);
    if (totalTokens + tokens <= budget) {
      kept.push(block);
      totalTokens += tokens;
    } else if (block.priority <= 2) {
      // system_core and current_message are NEVER dropped
      kept.push(block);
      totalTokens += tokens;
    }
    // else: drop this block — over budget
  }

  return kept;
}

// Tool output truncator — prevents massive tool outputs filling context
export function truncateToolOutput(output: string, maxTokens = 500): string {
  if (estimateTokens(output) <= maxTokens) return output;
  const lines = output.split('\n');
  const kept = lines.slice(0, 20);
  const timestamp = Date.now();
  return [
    ...kept,
    `[... ${lines.length - 20} lines truncated. Use read_file tool on ` +
    `'tool-output-${timestamp}.txt' to access full output if needed.]`
  ].join('\n');
}
