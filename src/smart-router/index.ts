// src/smart-router/index.ts
// Gateway hook — wires smart router into OpenClaw's message pipeline.
// This is the ONLY file in smart-router/ that touches OpenClaw internals.

import { routeMessage } from './failover.js';

// Export the hook for OpenClaw's plugin/middleware system
export async function smartRouterHook(
  message: string,
  _context: unknown
): Promise<string> {
  return routeMessage(message);
}

export { classifyTask, getContextMode } from './classifier.js';
export { enforceContextBudget, truncateToolOutput } from './context-manager.js';
