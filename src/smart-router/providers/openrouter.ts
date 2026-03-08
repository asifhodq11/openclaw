export async function callOpenRouter(
  message: string,
  model: string,
  apiKey: string
): Promise<string> {
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
      'HTTP-Referer': 'https://github.com/asifhodq11/openclaw'
    },
    body: JSON.stringify({
      model,
      messages: [{ role: 'user', content: message }],
      max_tokens: 1024,
    }),
  });

  if (!response.ok) {
    const error = new Error(`OpenRouter error ${response.status}`) as any;
    error.status = response.status;
    error.provider = 'openrouter';
    throw error;
  }

  const data = await response.json();
  return data.choices[0].message.content;
}
