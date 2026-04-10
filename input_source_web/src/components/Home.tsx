import React from 'react';
import { StampData } from '@/src/types';
import { Stamp } from './Stamp';
import { Plus, Folder, Search, LogOut } from 'lucide-react';
import { motion } from 'motion/react';

interface HomeProps {
  stamps: StampData[];
  onAdd: () => void;
  onOpenAlbum: () => void;
  onSelectStamp: (id: string) => void;
  onLogout: () => void;
}

export const Home: React.FC<HomeProps> = ({ stamps, onAdd, onOpenAlbum, onSelectStamp, onLogout }) => {
  // Group stamps by date
  const groupedStamps: Record<string, StampData[]> = stamps.reduce((acc, stamp) => {
    const date = new Date(stamp.date).toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
    if (!acc[date]) acc[date] = [];
    acc[date].push(stamp);
    return acc;
  }, {} as Record<string, StampData[]>);

  return (
    <div className="min-h-screen bg-[#f8f5ed] pb-32">
      {/* Header */}
      <header className="p-6 flex justify-between items-center bg-[#f8f5ed]/80 backdrop-blur-md sticky top-0 z-10">
        <button
          onClick={onOpenAlbum}
          className="w-12 h-12 bg-[#fefaf5] rounded-2xl shadow-sm text-[#757575] flex items-center justify-center transition-transform active:scale-90"
        >
          <Folder size={24} />
        </button>
        <h1 className="text-[22px] font-sans font-bold text-[#757575] tracking-widest">Trang chủ</h1>
        <button
          onClick={onLogout}
          className="w-12 h-12 bg-[#fefaf5] rounded-2xl shadow-sm text-[#757575] flex items-center justify-center transition-transform active:scale-90"
        >
          <LogOut size={24} />
        </button>
      </header>

      {/* Content */}
      <main className="p-6 space-y-10">
        {stamps.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-32 text-center space-y-6">
            <div className="w-32 h-32 bg-[#fefaf5] rounded-full flex items-center justify-center shadow-inner">
              <Search size={48} className="text-[#757575]" />
            </div>
            <div className="space-y-2">
              <h3 className="text-[19px] font-serif font-bold text-[#a0a09c] tracking-wide">Chưa có kỷ niệm nào!</h3>
              <p className="text-[16px] font-serif text-[#a0a09c] max-w-[200px] mx-auto tracking-normal">Hãy bắt đầu lưu giữ những kỷ niệm đầu tiên của bạn!</p>
            </div>
          </div>
        ) : (
          Object.entries(groupedStamps).map(([date, dateStamps]) => (
            <section key={date} className="bg-white rounded-2xl p-4 shadow-sm border border-slate-50 space-y-4 overflow-hidden">
              <div className="flex flex-col gap-0.5 px-2">
                <h2 className="text-[16px] font-serif font-bold text-[#a0a09c] tracking-tight">{date}</h2>
                <span className="text-[13px] font-serif font-medium text-[#a0a09c]">{dateStamps.length} stamps</span>
              </div>

              <div className="relative -mx-4">
                <div
                  className="overflow-x-auto scrollbar-none snap-x snap-mandatory px-8"
                  style={{
                    WebkitMaskImage: 'linear-gradient(to right, transparent, black 32px, black calc(100% - 32px), transparent)',
                    maskImage: 'linear-gradient(to right, transparent, black 32px, black calc(100% - 32px), transparent)',
                  }}
                >
                  <div className="flex gap-6 py-4 min-w-max">
                    {dateStamps.map((stamp, idx) => {
                      const rotation = idx % 2 === 0 ? "-rotate-2" : "rotate-2";

                      return (
                        <motion.div
                          key={stamp.id}
                          initial={{ opacity: 0, scale: 0.9, y: 15 }}
                          animate={{ opacity: 1, scale: 1, y: 0 }}
                          transition={{ delay: idx * 0.05 }}
                          className="flex-shrink-0 snap-center"
                          onClick={() => onSelectStamp(stamp.id)}
                        >
                          <div className={rotation}>
                            <Stamp
                              src={stamp.imageUrl}
                              className="
                                w-28
                                aspect-[3/4]
                                transition-transform
                                hover:scale-105
                                duration-300
                              "
                            />
                          </div>
                        </motion.div>
                      );
                    })}
                    {/* Trailing space for the mask effect to work correctly */}
                    <div className="w-8 flex-shrink-0" />
                  </div>
                </div>
              </div>
            </section>
          ))
        )}
      </main>

      {/* Floating Add Button */}
      <div className="fixed bottom-8 right-3 pointer-events-none">
        <button
          onClick={onAdd}
          className="w-16 h-16 bg-[#fefaf5] backdrop-blur-md rounded-full shadow-sm text-[#757575] flex items-center justify-center pointer-events-auto transition-colors"
        >
          <Plus size={32} />
        </button>
      </div>
    </div>
  );
};
