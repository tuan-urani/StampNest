import React, { useState } from 'react';
import { StampData } from '@/src/types';
import { Stamp } from './Stamp';
import { ChevronLeft, MoreHorizontal, Trash2, AlertCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface StampDetailsViewProps {
  stamp: StampData;
  onBack: () => void;
  onDelete: (id: string) => void;
}

export const StampDetailsView: React.FC<StampDetailsViewProps> = ({ stamp, onBack, onDelete }) => {
  const [showMenu, setShowMenu] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  const dateObj = new Date(stamp.date);
  const timeStr = dateObj.toLocaleTimeString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  });

  const dateStr = dateObj.toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric'
  });

  const handleDelete = () => {
    setShowDeleteConfirm(false);
    onDelete(stamp.id);
  };

  return (
    <div className="fixed inset-0 bg-[#f8f5ed] z-[60] flex flex-col overflow-hidden">
      {/* Header */}
      <header className="p-6 flex justify-between items-center z-10 relative">
        <button
          onClick={onBack}
          className="w-12 h-12 bg-[#fefaf5] rounded-2xl shadow-sm text-[#757575] flex items-center justify-center transition-transform active:scale-90"
        >
          <ChevronLeft size={24} />
        </button>
        <div className="relative">
          <button
            onClick={() => setShowMenu(!showMenu)}
            className="w-12 h-12 bg-[#fefaf5] rounded-2xl shadow-sm text-[#757575] flex items-center justify-center transition-transform active:scale-90"
          >
            <MoreHorizontal size={24} />
          </button>

          <AnimatePresence>
            {showMenu && (
              <>
                <div
                  className="fixed inset-0 z-10"
                  onClick={() => setShowMenu(false)}
                />
                <motion.div
                  initial={{ opacity: 0, scale: 0.95, y: 10 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95, y: 10 }}
                  className="absolute right-0 mt-2 w-48 bg-white rounded-2xl shadow-sm z-20 py-2 border border-slate-50"
                >
                  <button
                    onClick={() => {
                      setShowMenu(false);
                      setShowDeleteConfirm(true);
                    }}
                    className="w-full px-4 py-3 text-left text-red-500 text-[16px] font-serif font-bold flex items-center gap-3 hover:bg-red-50 transition-colors"
                  >
                    <Trash2 size={18} />
                    Xoá kỉ niệm
                  </button>
                </motion.div>
              </>
            )}
          </AnimatePresence>
        </div>
      </header>

      {/* Content */}
      <div className="flex-1 flex flex-col items-center justify-center px-8 pb-32">
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ type: 'spring', damping: 20, stiffness: 100 }}
          className="relative"
        >
          <Stamp
            src={stamp.imageUrl}
            className="w-64 aspect-[3/4] transition-transform"
          />
        </motion.div>

        {/* Info */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="mt-16 text-center space-y-1"
        >
          <h2 className="text-[22px] font-serif font-bold text-[#4a4a48] tracking-tight">
            {stamp.name}
          </h2>
          <p className="text-[16px] font-serif text-[#a0a09c] font-medium italic">
            {dateStr}
          </p>
        </motion.div>
      </div>

      {/* Delete Confirmation Modal */}
      <AnimatePresence>
        {showDeleteConfirm && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-6">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowDeleteConfirm(false)}
              className="absolute inset-0 bg-black/20 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              className="relative w-full max-w-xs bg-white rounded-[24px] p-8 shadow-2xl text-center space-y-6"
            >
              <div className="w-16 h-16 bg-red-50 rounded-full flex items-center justify-center text-red-500 mx-auto">
                <AlertCircle size={32} />
              </div>
              <div className="space-y-2">
                <h3 className="text-[19px] font-serif font-bold text-[#4a4a48]">Xoá kỉ niệm?</h3>
                <p className="text-[13px] font-serif text-[#a0a09c]">Kỉ niệm này sẽ bị xoá vĩnh viễn khỏi Album và Cloud VPS của bạn.</p>
              </div>
              <div className="flex flex-col gap-3 pt-2">
                <button
                  onClick={handleDelete}
                  className="w-full py-4 bg-red-500 text-white rounded-2xl text-[16px] font-serif font-bold active:scale-95 transition-transform"
                >
                  Xác nhận xoá
                </button>
                <button
                  onClick={() => setShowDeleteConfirm(false)}
                  className="w-full py-4 bg-[#fefaf5] text-[#757575] rounded-2xl text-[16px] font-serif font-bold active:scale-95 transition-transform"
                >
                  Hủy bỏ
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};
