// NO OpenClaw imports. Pure logic only.
export type TaskTier = 'simple' | 'medium' | 'complex';

const COMPLEX_SIGNALS = [
  'debug', 'program', 'algorithm', 'analyze', 'research',
  'compare', 'explain in detail', 'reason', 'think through',
  'implement', 'refactor', 'optimize', 'architecture'
];

const SIMPLE_SIGNALS = [
  'hi', 'hello', 'thanks', 'what is', 'translate', 'define',
  'how do i', 'quick', 'brief', 'tldr', 'hey'
];

export function classifyTask(message: string): TaskTier {
  const lower = message.toLowerCase().trim();
  const wordCount = lower.split(/\s+/).length;

  // Tier 3: must have BOTH a complex signal AND >40 words
  // This prevents "write a haiku" from burning Gemini Pro quota
  if (wordCount > 40 && COMPLEX_SIGNALS.some(s => lower.includes(s))) {
    return 'complex';
  }

  // Tier 1: short AND contains simple signal
  if (wordCount < 15 && SIMPLE_SIGNALS.some(s => lower.includes(s))) {
    return 'simple';
  }

  // Everything else: Tier 2
  return 'medium';
}

export function getContextMode(tier: TaskTier): 'light' | 'standard' | 'full' {
  if (tier === 'simple')  return 'light';    // no workspace, no memory
  if (tier === 'medium')  return 'standard'; // workspace summary, recent memory
  return 'full';                             // everything
}
