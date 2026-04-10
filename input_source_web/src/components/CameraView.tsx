import React, { useState, useCallback, useRef } from 'react';
import Cropper from 'react-easy-crop';
import { Camera, X, Check, Upload, RotateCcw } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import CameraCapture from './CameraCapture';

interface CameraViewProps {
  onCapture: (croppedImage: string) => void;
  onBack: () => void;
}

export const CameraView: React.FC<CameraViewProps> = ({ onCapture, onBack }) => {
  const [image, setImage] = useState<string | null>(null);
  const [crop, setCrop] = useState({ x: 0, y: 0 });
  const [zoom, setZoom] = useState(1);
  const [croppedAreaPixels, setCroppedAreaPixels] = useState<any>(null);
  const [isCameraActive, setIsCameraActive] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const onCropComplete = useCallback((_croppedArea: any, croppedAreaPixels: any) => {
    setCroppedAreaPixels(croppedAreaPixels);
  }, []);

  const handleCapture = (capturedImage: string) => {
    setImage(capturedImage);
    setIsCameraActive(false);
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = () => {
        setImage(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const getCroppedImg = async () => {
    if (!image || !croppedAreaPixels) return;

    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const img = new Image();
    img.src = image;
    await new Promise((resolve) => (img.onload = resolve));

    const cropArea = document.querySelector('.hide-crop-area') as HTMLElement;
    const container = cropArea?.parentElement;

    if (!cropArea || !container) return;

    // Dynamically calculate the ratio based on CSS-styled dimensions
    const widthRatio = cropArea.offsetWidth / container.offsetWidth;
    const heightRatio = cropArea.offsetHeight / container.offsetHeight;

    const subWidth = croppedAreaPixels.width * widthRatio;
    const subHeight = croppedAreaPixels.height * heightRatio;
    const subX = croppedAreaPixels.x + (croppedAreaPixels.width - subWidth) / 2;
    const subY = croppedAreaPixels.y + (croppedAreaPixels.height - subHeight) / 2;

    canvas.width = subWidth;
    canvas.height = subHeight;

    ctx.drawImage(
      img,
      subX,
      subY,
      subWidth,
      subHeight,
      0,
      0,
      subWidth,
      subHeight
    );

    onCapture(canvas.toDataURL('image/jpeg'));
  };

  return (
    <div className="fixed inset-0 bg-[#f8f5ed] z-50 flex flex-col">
      {/* Header */}
      {!isCameraActive && (
        <div className="absolute top-0 left-0 right-0 p-6 flex justify-between items-center z-20">
          <button onClick={onBack} className="p-3 bg-[#fefaf5] rounded-2xl shadow-sm text-[#757575] transition-colors">
            <X size={24} />
          </button>
          <div className="text-[22px] font-sans font-bold text-[#757575] tracking-widest">Tạo Stamp</div>
          <div className="w-10" /> {/* Spacer */}
        </div>
      )}

      {/* Main Content */}
      <div className="flex-1 relative overflow-hidden">
        {!image && !isCameraActive && (
          <div className="absolute inset-0 flex flex-col items-center justify-center gap-6 p-8">
            <div className="w-48 h-64 border-2 border-dashed border-[#757575] rounded-2xl flex items-center justify-center">
              <Camera size={48} className="text-[#757575]" />
            </div>
            <div className="flex flex-col gap-3 w-full max-w-xs">
              <button
                onClick={() => setIsCameraActive(true)}
                className="w-full py-4 bg-[#fefaf5] text-[16px] text-[#757575] font-serif rounded-2xl font-bold flex items-center justify-center gap-2 backdrop-blur-md"
              >
                <Camera size={20} /> Mở Camera
              </button>
              <button
                onClick={() => fileInputRef.current?.click()}
                className="w-full py-4 bg-[#fefaf5] text-[16px] text-[#757575] font-serif rounded-2xl font-bold flex items-center justify-center gap-2 backdrop-blur-md"
              >
                <Upload size={20} /> Tải ảnh lên
              </button>
              <input
                type="file"
                ref={fileInputRef}
                className="hidden"
                accept="image/*"
                onChange={handleFileUpload}
              />
            </div>
          </div>
        )}

        {isCameraActive && (
          <CameraCapture
            onCapture={handleCapture}
            onClose={() => setIsCameraActive(false)}
          />
        )}

        {image && (
          <div className="absolute inset-0 flex flex-col items-center justify-center min-h-screen bg-[#f8f5ed]">
            <div className="relative w-full max-w-sm aspect-[9/16] flex items-center justify-center">
              {/* Cropper is now larger for viewing (w-[80%]) */}
              <div className="absolute w-[80%] aspect-[3/4] z-0 mt-[-2%] border-2 border-dashed border-[#757575] rounded-2xl overflow-hidden">
                <Cropper
                  image={image}
                  crop={crop}
                  zoom={zoom}
                  aspect={3 / 4}
                  onCropChange={setCrop}
                  onCropComplete={onCropComplete}
                  onZoomChange={setZoom}
                  showGrid={false}
                  restrictPosition={false} // Allow dragging outside bounds
                  minZoom={0.2} // Allow zooming out more
                  cropAreaStyle={{ border: 'none', boxShadow: 'none', width: '', height: '' }}
                  classes={{
                    containerClassName: "bg-[#f8f5ed]",
                    cropAreaClassName: "hide-crop-area", // Use custom CSS class to hide guides
                  }}
                />
              </div>

              {/* The Frame Image Overlay - Rotated to be vertical */}
              <div className="absolute inset-0 z-10 pointer-events-none flex items-center justify-center p-4">
                <img
                  src="https://figmatelia.figma.site/_assets/v11/005f14c479988123f230e03d4bbe68e67ece9192.png"
                  alt="Stamp Frame"
                  className="w-full h-full object-contain rotate-90"
                  referrerPolicy="no-referrer"
                />
              </div>
            </div>

            {/* Controls */}
            <div className="absolute bottom-12 left-0 right-0 px-8 flex justify-between items-center z-20">
              <button
                onClick={() => setImage(null)}
                className="p-3 bg-[#fefaf5] rounded-2xl backdrop-blur-md text-[#757575] transition-colors"
              >
                <RotateCcw size={24} />
              </button>

              <button
                onClick={getCroppedImg}
                className="px-8 py-3 bg-[#fefaf5] text-[16px] text-[#757575] font-serif rounded-2xl font-bold flex items-center justify-center backdrop-blur-md gap-2"
              >
                <Check size={24} /> Cắt Stamp
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

