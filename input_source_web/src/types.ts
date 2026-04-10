export interface StampData {
  id: string;
  name: string;
  imageUrl: string; // Base64 or Blob URL
  date: string; // ISO string
  album?: string;
}

export type AppState = 'home' | 'camera' | 'save' | 'album' | 'details' | 'login' | 'register';
