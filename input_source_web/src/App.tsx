import React, { useState, useEffect } from 'react';
import { Home } from './components/Home';
import { CameraView } from './components/CameraView';
import { SaveView } from './components/SaveView';
import { AlbumView } from './components/AlbumView';
import { StampDetailsView } from './components/StampDetailsView';
import { LoginView } from './components/LoginView';
import { RegisterView } from './components/RegisterView';
import { StampData, AppState } from './types';
import { AnimatePresence, motion } from 'motion/react';
import { stampApi } from './lib/api';
import localforage from 'localforage';

export default function App() {
  const initialToken = localStorage.getItem('stampverse_token');
  const [view, setView] = useState<AppState>(initialToken ? 'home' : 'login');
  const [stamps, setStamps] = useState<StampData[]>([]);
  const [currentCapture, setCurrentCapture] = useState<string | null>(null);
  const [selectedStampId, setSelectedStampId] = useState<string | null>(null);
  const [token, setToken] = useState<string | null>(initialToken);
  const [user, setUser] = useState<any>(null);

  // 1. Initial Load: Cache First
  useEffect(() => {
    const loadCache = async () => {
      try {
        const cachedStamps = await localforage.getItem<StampData[]>('stampverse_stamps');
        if (cachedStamps) {
          setStamps(cachedStamps);
        }
      } catch (e) {
        console.error("Cache load failed:", e);
      }
    };
    loadCache();
  }, []);

  // 2. Sync from API if logged in
  const fetchStamps = async () => {
    if (!token) return;
    try {
      const response = await stampApi.list();
      if (response.status === 'success') {
        const serverStamps = response.data;
        setStamps(serverStamps);
        // Persist to local cache for next offline/quick load
        await localforage.setItem('stampverse_stamps', serverStamps);
      }
    } catch (e) {
      console.error("Error syncing stamps:", e);
    }
  };

  useEffect(() => {
    if (token) {
      fetchStamps();
    } else {
      setView('login');
    }
  }, [token]);

  const handleCapture = (imageUrl: string) => {
    setCurrentCapture(imageUrl);
    setView('save');
  };

  const handleSave = async (name: string) => {
    if (!currentCapture) return;

    const stampPayload = {
      name,
      imageUrl: currentCapture,
      date: new Date().toISOString(),
    };

    // Optimistic Update Locally
    const tempId = Date.now().toString();
    const optimisticStamp: StampData = { id: tempId, ...stampPayload };
    const updatedStamps = [optimisticStamp, ...stamps];
    setStamps(updatedStamps);
    await localforage.setItem('stampverse_stamps', updatedStamps);
    setView('home');

    try {
      const response = await stampApi.upload(stampPayload);
      if (response.status === 'success') {
        fetchStamps();
      }
    } catch (e) {
      console.error("Error uploading stamp:", e);
    }
    
    setCurrentCapture(null);
  };

  const handleBack = () => {
    if (!token) {
      setView('login');
      return;
    }

    if (view === 'save') {
      setView('camera');
    } else if (view === 'details') {
      setView('album');
    } else if (view === 'register') {
      setView('login');
    } else {
      setView('home');
    }
  };
  
  const handleSelectStamp = (id: string) => {
    setSelectedStampId(id);
    setView('details');
  };

  const handleDeleteStamp = async (id: string) => {
    try {
      // 1. VPS Delete
      await stampApi.delete(id);
      
      // 2. Local State Delete
      const filteredStamps = stamps.filter(s => s.id !== id);
      setStamps(filteredStamps);
      
      // 3. Cache Delete
      await localforage.setItem('stampverse_stamps', filteredStamps);
      
      setView('album');
      setSelectedStampId(null);
    } catch (e) {
      console.error("Delete failed:", e);
    }
  };

  const handleLoginSuccess = (token: string, user: any) => {
    localStorage.setItem('stampverse_token', token);
    setToken(token);
    setUser(user);
    setView('home');
  };

  const handleLogout = async () => {
    localStorage.removeItem('stampverse_token');
    await localforage.removeItem('stampverse_stamps');
    setToken(null);
    setUser(null);
    setStamps([]);
    setView('login');
  };

  const selectedStamp = stamps.find(s => s.id === selectedStampId);

  return (
    <div className="mx-auto h-screen relative overflow-hidden bg-[#F9F7F2]">
      <AnimatePresence mode="wait">
        {view === 'login' && (
          <motion.div
            key="login"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="h-full"
          >
            <LoginView 
              onSuccess={handleLoginSuccess}
              onBack={() => {}} 
              onSwitchToRegister={() => setView('register')}
            />
          </motion.div>
        )}

        {view === 'register' && (
          <motion.div
            key="register"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="h-full"
          >
            <RegisterView 
              onSuccess={() => setView('login')}
              onBack={() => setView('login')} 
              onSwitchToLogin={() => setView('login')}
            />
          </motion.div>
        )}

        {view === 'home' && (
          <motion.div
            key="home"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="h-full"
          >
            <Home 
              stamps={stamps} 
              onAdd={() => setView('camera')} 
              onOpenAlbum={() => setView('album')}
              onSelectStamp={handleSelectStamp}
              onLogout={handleLogout}
            />
          </motion.div>
        )}
        
        {view === 'camera' && (
          <motion.div
            key="camera"
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 200 }}
            className="h-full"
          >
            <CameraView onCapture={handleCapture} onBack={handleBack} />
          </motion.div>
        )}

        {view === 'save' && currentCapture && (
          <motion.div
            key="save"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="h-full"
          >
            <SaveView 
              imageUrl={currentCapture} 
              onSave={handleSave} 
              onBack={handleBack} 
            />
          </motion.div>
        )}

        {view === 'album' && (
          <motion.div
            key="album"
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 200 }}
            className="h-full"
          >
            <AlbumView 
              stamps={stamps} 
              onBack={handleBack} 
              onSelectStamp={handleSelectStamp} 
            />
          </motion.div>
        )}

        {view === 'details' && selectedStamp && (
          <motion.div
            key="details"
            initial={{ opacity: 0, scale: 1.1 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="h-full"
          >
            <StampDetailsView 
              stamp={selectedStamp} 
              onBack={handleBack} 
              onDelete={handleDeleteStamp}
            />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
