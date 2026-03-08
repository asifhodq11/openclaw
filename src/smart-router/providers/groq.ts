export async function callGroq(
  message: string,
  model: string,
  apiKey: string
): Promise<string> {
  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages: [{ role: 'user', content: message }],
      max_tokens: 1024,
    }),
  });

  if (!response.ok) {
    const error = new Error(`Groq error ${response.status}`) as any;
    error.status = response.status;
    error.provider = 'groq';
    throw error;
  }

  const data = await response.json();
  return data.choices[0].message.content;
}
