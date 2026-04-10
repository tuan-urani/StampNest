import React from 'react';
import { StampData } from '@/src/types';
import { Stamp } from './Stamp';
import { ChevronLeft, MoreHorizontal } from 'lucide-react';
import { motion } from 'motion/react';

interface AlbumViewProps {
  stamps: StampData[];
  onBack: () => void;
  onSelectStamp: (id: string) => void;
}

export const AlbumView: React.FC<AlbumViewProps> = ({ stamps, onBack, onSelectStamp }) => {
  return (
    <div className="fixed inset-0 bg-[#f8f5ed] z-50 flex flex-col overflow-hidden">
      {/* Header */}
      <header className="p-6 flex justify-between items-center bg-[#f8f5ed]/80 backdrop-blur-md sticky top-0 z-10">
        <button
          onClick={onBack}
          className="w-12 h-12 bg-[#fefaf5] rounded-2xl shadow-sm text-[#757575] flex items-center justify-center transition-transform active:scale-90"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-[20px] font-sans font-bold text-[#757575] tracking-widest text-center">Thư viện</h1>
        <button className="w-12 h-12 bg-[#fefaf5] rounded-2xl shadow-sm text-[#757575] flex items-center justify-center transition-transform active:scale-90">
          <MoreHorizontal size={24} />
        </button>
      </header>

      {/* Grid Content */}
      <div className="flex-1 overflow-y-auto px-6 pb-12 scrollbar-none">
        {stamps.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full py-32 text-center opacity-50">
            <p className="text-[19px] font-serif text-[#a0a09c] max-w-[200px] mx-auto tracking-normal">Album trống</p>
          </div>
        ) : (
          <div className="grid grid-cols-3 gap-x-4 gap-y-10 pt-4">
            {stamps.map((stamp, idx) => (
              <motion.div
                key={stamp.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.03 }}
                onClick={() => onSelectStamp(stamp.id)}
                className="flex flex-col items-center cursor-pointer"
              >
                <Stamp
                  src={stamp.imageUrl}
                  className="w-full aspect-[3/4] transition-transform hover:scale-105 active:scale-95"
                />
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
