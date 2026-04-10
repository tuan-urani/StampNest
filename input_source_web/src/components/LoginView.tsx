import React, { useState } from 'react';
import { authApi } from '../lib/api';
import { motion } from 'motion/react';
import { ChevronLeft, Lock, User, ArrowRight } from 'lucide-react';

interface LoginViewProps {
  onSuccess: (token: string, user: any) => void;
  onBack: () => void;
  onSwitchToRegister: () => void;
}

export const LoginView: React.FC<LoginViewProps> = ({ onSuccess, onBack, onSwitchToRegister }) => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const response = await authApi.login(username, password);
      if (response.status === 'success') {
        onSuccess(response.token, response.user);
      } else {
        setError(response.message || 'Đăng nhập thất bại');
      }
    } catch (err: any) {
      setError(err.message || 'Có lỗi xảy ra, vui lòng thử lại');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-[#f8f5ed] z-[100] flex flex-col p-6">
      {/* Header */}
      <div className="mb-12">
        <button
          onClick={onBack}
          className="w-12 h-12 bg-[#fefaf5] rounded-2xl shadow-sm text-[#757575] flex items-center justify-center transition-transform active:scale-90"
        >
          <ChevronLeft size={24} />
        </button>
      </div>

      {/* Hero */}
      <div className="mb-12">
        <h1 className="text-[22px] font-serif font-bold text-[#4a4a48] tracking-tight">Đăng nhập</h1>
        <p className="text-[16px] font-serif text-[#a0a09c] mt-2 italic font-medium">Lưu giữ kỷ niệm trên đám mây của riêng bạn.</p>
      </div>

      {/* Form */}
      <form onSubmit={handleLogin} className="space-y-6 flex-1">
        <div className="space-y-4">
          <div className="relative group">
            <div className="absolute left-4 top-1/2 -translate-y-1/2 text-[#a0a09c] group-focus-within:text-[#757575] transition-colors">
              <User size={20} />
            </div>
            <input
              type="text"
              placeholder="Tên đăng nhập"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full bg-white/50 border-2 border-slate-100 rounded-2xl py-4 pl-12 pr-4 text-[16px] font-serif font-bold text-[#757575] focus:outline-none focus:border-[#757575] transition-all bg-opacity-40 focus:bg-white"
              required
            />
          </div>

          <div className="relative group">
            <div className="absolute left-4 top-1/2 -translate-y-1/2 text-[#a0a09c] group-focus-within:text-[#757575] transition-colors">
              <Lock size={20} />
            </div>
            <input
              type="password"
              placeholder="Mật khẩu"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full bg-white/50 border-2 border-slate-100 rounded-2xl py-4 pl-12 pr-4 text-[16px] font-serif font-bold text-[#757575] focus:outline-none focus:border-[#757575] transition-all bg-opacity-40 focus:bg-white"
              required
            />
          </div>
        </div>

        {error && (
          <motion.p
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-red-400 text-[13px] font-serif font-bold text-center"
          >
            {error}
          </motion.p>
        )}

        <div className="pt-4">
          <button
            type="submit"
            disabled={isLoading}
            className="w-full py-4 bg-[#fefaf5] text-[16px] text-[#757575] font-serif rounded-2xl shadow-sm font-bold flex items-center justify-center backdrop-blur-md gap-3 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
          >
            {isLoading ? 'Đang thực hiện...' : 'Tiếp tục'} <ArrowRight size={20} />
          </button>
        </div>
      </form>

      {/* Footer */}
      <div className="mt-auto text-center pb-8 sticky bottom-0">
        <button
          onClick={onSwitchToRegister}
          className="text-[16px] font-serif text-[#a0a09c] hover:text-[#757575] transition-colors"
        >
          Chưa có tài khoản? <span className="font-bold">Đăng ký mới</span>
        </button>
      </div>
    </div>
  );
};
