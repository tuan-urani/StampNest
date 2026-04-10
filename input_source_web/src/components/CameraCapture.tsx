import React, { useRef, useEffect, useState, useCallback } from 'react';
import {  Camera, Upload, RefreshCw, Grid3X3, X } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface CameraCaptureProps {
  onCapture: (image: string) => void;
  onClose: () => void;
}

type ZoomLevel = 1 | 2 | 3 | 5;

const CameraCapture: React.FC<CameraCaptureProps> = ({ onCapture, onClose }) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [isInitializing, setIsInitializing] = useState(true);
  const [facingMode, setFacingMode] = useState<'user' | 'environment'>('environment');
  const [showGrid, setShowGrid] = useState(true);
  const [zoom, setZoom] = useState<ZoomLevel>(1);
  const [hasHardwareZoom, setHasHardwareZoom] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const stopCamera = useCallback(() => {
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
      setStream(null);
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
  }, [stream]);

  const startCamera = async () => {
    setIsInitializing(true);
    setError(null);
    
    const constraints: MediaStreamConstraints = { 
      video: { 
        facingMode: facingMode, 
        width: { ideal: 1440 }, 
        height: { ideal: 1080 }
      }, 
      audio: false 
    };

    try {
      let mediaStream: MediaStream;
      try {
        mediaStream = await navigator.mediaDevices.getUserMedia(constraints);
      } catch (firstTryError) {
        console.warn("First camera attempt failed, trying fallback...", firstTryError);
        mediaStream = await navigator.mediaDevices.getUserMedia({ 
          video: true, 
          audio: false 
        });
      }

      setStream(mediaStream);
      
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream;
        
        videoRef.current.onloadedmetadata = async () => {
          try {
            await videoRef.current?.play();
            setIsInitializing(false);
          } catch (e) {
            console.error("Video play failed:", e);
          }
        };
      }
    } catch (err: any) {
      console.error("Camera access error:", err);
      let errorMsg = 'Không thể khởi động Camera.';
      if (err.name === 'NotAllowedError') {
        errorMsg = 'Vui lòng cấp quyền Camera trong cài đặt trình duyệt.';
      } else if (err.name === 'NotFoundError' || err.name === 'DevicesNotFoundError') {
        errorMsg = 'Không tìm thấy thiết bị Camera trên máy của bạn.';
      }
      setError(errorMsg);
      setIsInitializing(false);
    }
  };

  useEffect(() => {
    startCamera();
    return () => {
      if (stream) {
        stream.getTracks().forEach(track => track.stop());
      }
    };
  }, [facingMode]);

  useEffect(() => {
    const applyHardwareZoom = async () => {
      if (!stream) return;
      const track = stream.getVideoTracks()[0];
      if (!track) return;

      try {
        const capabilities = typeof track.getCapabilities === 'function' ? track.getCapabilities() as any : null;
        if (capabilities && capabilities.zoom) {
          const minZoom = capabilities.zoom.min || 1;
          const maxZoom = capabilities.zoom.max || 1;
          const targetZoom = Math.min(Math.max(zoom, minZoom), maxZoom);
          
          await track.applyConstraints({
            advanced: [{ zoom: targetZoom }]
          } as any);
          setHasHardwareZoom(true);
        } else {
          setHasHardwareZoom(false);
        }
      } catch (e) {
        setHasHardwareZoom(false);
      }
    };
    
    applyHardwareZoom();
  }, [zoom, stream]);

  const captureFrame = () => {
    if (videoRef.current && canvasRef.current) {
      const video = videoRef.current;
      const canvas = canvasRef.current;
      const context = canvas.getContext('2d', { alpha: false });
      const vWidth = video.videoWidth;
      const vHeight = video.videoHeight;
      if (vWidth === 0 || vHeight === 0) return;

      canvas.width = vWidth;
      canvas.height = vHeight;
      
      if (context) {
        context.imageSmoothingEnabled = true;
        context.imageSmoothingQuality = 'high';
        if (facingMode === 'user') {
          context.translate(canvas.width, 0);
          context.scale(-1, 1);
        }
        context.drawImage(video, 0, 0, canvas.width, canvas.height);
        
        const dataUrl = canvas.toDataURL('image/jpeg');
        onCapture(dataUrl);
      }
    }
  };

  const flipCamera = () => {
    setFacingMode(prev => prev === 'user' ? 'environment' : 'user');
  };

  return (
    <div className="fixed inset-0 bg-[#f8f5ed] z-[100] flex flex-col items-center select-none overflow-hidden">
      {/* Header synchronized with CameraView */}
      <div className="w-full flex justify-between items-center px-6 pt-6 pb-4 z-50">
        <button 
          onClick={onClose} 
          className="p-3 bg-[#fefaf5] rounded-2xl shadow-sm text-[#757575] transition-colors active:scale-90"
        >
          <X size={24} />
        </button>

        <div className="text-[22px] font-sans font-bold text-[#757575] tracking-widest">
          Chụp ảnh
        </div>
        <div className="w-10" /> {/* Spacer */}
      </div>

      {/* Camera Preview Container - 3:4 Aspect Ratio */}
      <div className="relative w-[80%] aspect-[3/4] max-w-[400px] rounded-2xl overflow-hidden shadow-sm border-2 border-dashed border-[#757575] isolate mt-4">
        {isInitializing && !error && (
          <div className="absolute inset-0 flex items-center justify-center bg-[#f8f5ed] z-10">
            <div className="w-8 h-8 border-2 border-[#757575]/10 border-t-[#757575] rounded-full animate-spin" />
          </div>
        )}

        {error && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-[#f8f5ed] z-20 p-6 text-center">
            <p className="text-[#757575] text-[13px] mb-4 font-medium">{error}</p>
            <button onClick={startCamera} className="bg-[#fefaf5] text-[#757575] px-6 py-2 rounded-full font-bold text-[13px] active:scale-95 transition-transform shadow-sm">
            Thử lại
            </button>
          </div>
        )}
        
        <video 
          ref={videoRef} 
          autoPlay 
          playsInline 
          muted
          className="w-full h-full rounded-2xl transition-transform duration-300 ease-out"
          style={{
            objectFit: "contain",
            transform: `
              ${facingMode === "user" ? "scaleX(-1)" : ""}
              scale(${hasHardwareZoom ? 1 : zoom})
            `,
            transformOrigin: "center",
            WebkitMaskImage: '-webkit-radial-gradient(white, black)'
          }}
        />
        
        {showGrid && (
          <div className="absolute inset-0 pointer-events-none z-10 grid grid-cols-3 grid-rows-3 opacity-40">
            <div className="border-r border-b border-[#757575]"></div>
            <div className="border-r border-b border-[#757575]"></div>
            <div className="border-b border-[#757575]"></div>
            <div className="border-r border-b border-[#757575]"></div>
            <div className="border-r border-b border-[#757575]"></div>
            <div className="border-b border-[#757575]"></div>
            <div className="border-r border-[#757575]"></div>
            <div className="border-r border-[#757575]"></div>
            <div></div>
          </div>
        )}
      </div>

      {/* Zoom Controls */}
      <div className="mt-4 mb-4 z-50">
        <div className="bg-[#fefaf5] p-1 rounded-full shadow-sm border border-[#757575]/10 flex gap-0.5">
          {[1, 2, 3, 5].map((level) => (
            <button
              key={level}
              onClick={() => setZoom(level as ZoomLevel)}
              className={`relative w-10 h-10 rounded-full flex items-center justify-center transition-all active:scale-90`}
            >
              {zoom === (level as ZoomLevel) && (
                <motion.div 
                  layoutId="zoom-bg"
                  className="absolute inset-0 bg-[#757575] rounded-full"
                  initial={false}
                  transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
                />
              )}
              <span className={`relative text-[13px] font-serif font-bold ${zoom === level ? 'text-[#fefaf5]' : 'text-[#757575] hover:text-[#555]'}`}>
                {level}x
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* Bottom Controls */}
      <div className="w-full flex justify-between items-center px-10 mb-12 z-50">
        <button 
          onClick={flipCamera}
          className="w-14 h-14 bg-[#fefaf5] rounded-2xl flex items-center justify-center shadow-sm text-[#757575] active:scale-90 transition-transform group"
        >
          <RefreshCw size={24} className="group-hover:rotate-180 transition-transform duration-500" />
        </button>
        
        <button 
          onClick={captureFrame}
          disabled={isInitializing || !!error}
          className="w-14 h-14 bg-[#fefaf5] rounded-2xl flex items-center justify-center shadow-sm text-[#757575] active:scale-90 transition-transform group"
        >
          <Camera size={24} className="transition-transform duration-500" />
        </button>

        <button
          onClick={() => setShowGrid(!showGrid)} 
          className={`w-14 h-14 rounded-2xl flex items-center justify-center shadow-sm transition-transform group active:scale-90
            ${showGrid ? 'bg-[#757575] text-[#fefaf5]' : 'bg-[#fefaf5] text-[#757575]'}`}
        >
          <Grid3X3 size={24} className="transition-transform duration-500" />
        </button>
      </div>

      <canvas ref={canvasRef} className="hidden" />
    </div>
  );
};


export default CameraCapture;

