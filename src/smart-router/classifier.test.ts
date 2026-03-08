import { describe, it, expect } from 'vitest';
import { classifyTask } from './classifier.js';

describe('classifyTask', () => {
  it('classifies short greeting as simple', () => {
    expect(classifyTask('hi')).toBe('simple');
    expect(classifyTask('hello there')).toBe('simple');
    expect(classifyTask('thanks!')).toBe('simple');
  });

  it('classifies long complex request as complex', () => {
    const msg = 'Can you help me debug this algorithm and analyze why the '
      + 'performance degrades on large inputs? I need you to think through '
      + 'the time complexity and suggest optimizations.';
    expect(classifyTask(msg)).toBe('complex');
  });

  it('does NOT classify short write request as complex (quota protection)', () => {
    // "write a haiku" must NOT burn Gemini Pro — word count gate
    expect(classifyTask('write a haiku about rain')).toBe('medium');
  });

  it('classifies everything else as medium', () => {
    expect(classifyTask('What is the capital of France?')).toBe('medium');
    expect(classifyTask('Summarize this paragraph for me')).toBe('medium');
  });
});
