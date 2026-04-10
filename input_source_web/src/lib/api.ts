const API_BASE = 'https://snap.io.vn/api';

/**
 * Common fetch wrapper to handle auth tokens and robust JSON parsing.
 * Handles cases where PHP servers might output warnings before JSON.
 */
async function request(endpoint: string, options: RequestInit = {}) {
  const token = localStorage.getItem('stampverse_token');
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
    ...options.headers,
  };

  try {
    const response = await fetch(`${API_BASE}${endpoint}`, {
      ...options,
      headers,
    });

    const rawText = await response.text();
    
    // Extract JSON in case of PHP warnings/noise
    let data;
    try {
      const jsonMatch = rawText.match(/\{[\s\S]*\}|\[[\s\S]*\]/);
      data = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(rawText);
    } catch (e) {
      throw new Error(`Invalid server response: ${rawText.substring(0, 100)}...`);
    }

    if (!response.ok || data.status === 'error') {
      throw new Error(data.message || 'API request failed');
    }

    return data;
  } catch (error: any) {
    console.error(`API Error [${endpoint}]:`, error);
    throw error;
  }
}

export const authApi = {
  login: async (username: string, password: string) => {
    return request('/auth?action=login', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    });
  },
  register: async (username: string, phone: string, password: string) => {
    return request('/auth?action=register', {
      method: 'POST',
      body: JSON.stringify({ username, phone, password }),
    });
  }
};

export const stampApi = {
  list: async () => {
    return request('/stamps', { method: 'GET' });
  },
  upload: async (stamp: { name: string; imageUrl: string; date: string }) => {
    // imageUrl is Base64 from the app's current flow.
    // For VPS storage, let's suggest sending it as multipart if the server wants a file,
    // but for now we'll stick to JSON for simplicity unless specified.
    return request('/stamps', {
      method: 'POST',
      body: JSON.stringify(stamp),
    });
  },
  delete: async (id: string) => {
    return request(`/stamps?action=delete&id=${id}`, {
      method: 'GET', // Following the user's PHP code structure
    });
  }
};
