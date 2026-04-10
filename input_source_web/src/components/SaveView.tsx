import React, { useState } from 'react';
import { Stamp } from './Stamp';
import { ArrowLeft, Save } from 'lucide-react';

interface SaveViewProps {
  imageUrl: string;
  onSave: (name: string) => void;
  onBack: () => void;
}

export const SaveView: React.FC<SaveViewProps> = ({ imageUrl, onSave, onBack }) => {
  const [name, setName] = useState('');

  return (
    <div className="fixed inset-0 bg-[#f8f5ed] z-50 flex flex-col p-6">
      {/* Header */}
      <div className="flex justify-between items-center mb-12">
        <button onClick={onBack} className="p-3 bg-[#fefaf5] rounded-2xl shadow-sm text-[#757575] transition-colors">
          <ArrowLeft size={24} />
        </button>
        <h2 className="text-[22px] font-sans font-bold text-[#757575] tracking-widest">Lưu Stamp</h2>
        <div className="w-10" />
      </div>

      {/* Content */}
      <div className="flex-1 flex flex-col items-center justify-center gap-12">
        <div className="text-center">
          <input
            type="text"
            placeholder="Tên của stamp..."
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="bg-transparent border-b border-[#757575] text-[22px] font-serif font-bold text-[#757575] text-center focus:outline-none focus:border-[#757575] transition-colors w-full max-w-[150px] px-4 py-2"
            autoFocus
          />
          <p className="mt-4 text-[16px] font-serif text-[#a0a09c] font-medium">Đặt tên cho kỷ niệm của bạn</p>
        </div>

        <div className="relative group">
          <div className="absolute -inset-4 bg-white/50 blur-2xl rounded-full opacity-0 group-hover:opacity-100 transition-opacity" />
          <Stamp src={imageUrl} className="w-32 aspect-[3/4] transform hover:scale-105 transition-transform" />
        </div>
      </div>

      {/* Footer */}
      <div className="mt-auto pt-8">
        <button
          onClick={() => onSave(name || 'Kỷ niệm không tên')}
          disabled={!name.trim()}
          className="w-full py-4 bg-[#fefaf5] text-[16px] text-[#757575] font-serif rounded-2xl font-bold flex items-center justify-center backdrop-blur-md gap-3 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
        >
          <Save size={20} /> Lưu vào Album
        </button>
      </div>
    </div>
  );
};
