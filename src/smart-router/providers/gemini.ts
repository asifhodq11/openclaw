export async function callGemini(
  message: string,
  model: string,
  apiKey: string
): Promise<string> {
  const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      contents: [{ parts: [{ text: message }] }]
    }),
  });

  if (!response.ok) {
    const error = new Error(`Gemini error ${response.status}`) as any;
    error.status = response.status;
    error.provider = 'gemini';
    throw error;
  }

  const data = await response.json();
  return data.candidates[0].content.parts[0].text;
}
