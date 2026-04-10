import React, { useState } from 'react';
import { authApi } from '../lib/api';
import { motion } from 'motion/react';
import { ChevronLeft, Lock, User, ArrowRight, Check, Phone } from 'lucide-react';

interface RegisterViewProps {
  onSuccess: () => void;
  onBack: () => void;
  onSwitchToLogin: () => void;
}

export const RegisterView: React.FC<RegisterViewProps> = ({ onSuccess, onBack, onSwitchToLogin }) => {
  const [username, setUsername] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [isSuccess, setIsSuccess] = useState(false);

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    if (password !== confirmPassword) {
      setError('Mật khẩu xác nhận không khớp');
      setIsLoading(false);
      return;
    }

    try {
      const response = await authApi.register(username, phone, password);
      if (response.status === 'success') {
        setIsSuccess(true);
        setTimeout(() => onSuccess(), 2000);
      } else {
        setError(response.message || 'Đăng ký thất bại');
      }
    } catch (err: any) {
      setError(err.message || 'Có lỗi xảy ra, vui lòng thử lại');
    } finally {
      setIsLoading(false);
    }
  };

  if (isSuccess) {
    return (
      <div className="fixed inset-0 bg-[#f8f5ed] z-[100] flex flex-col items-center justify-center p-8">
        <motion.div
          initial={{ scale: 0.5, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center text-green-500 mb-6"
        >
          <Check size={40} />
        </motion.div>
        <h2 className="text-[24px] font-sans font-bold text-[#4a4a48]">Đăng ký thành công!</h2>
        <p className="text-[16px] font-serif text-[#a0a09c] mt-2">Đang chuyển bạn tới trang đăng nhập...</p>
      </div>
    );
  }

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
        <h1 className="text-[22px] font-serif font-bold text-[#4a4a48] tracking-tight">Tạo tài khoản</h1>
        <p className="text-[16px] font-serif text-[#a0a09c] mt-2 italic font-medium">Bắt đầu hành trình lưu trữ kỉ niệm vĩnh viễn.</p>
      </div>

      {/* Form */}
      <form onSubmit={handleRegister} className="space-y-6 flex-1">
        <div className="space-y-4">
          <div className="relative group">
            <div className="absolute left-4 top-1/2 -translate-y-1/2 text-[#a0a09c] group-focus-within:text-[#757575] transition-colors">
              <User size={20} />
            </div>
            <input
              type="text"
              placeholder="Tên đăng nhập mới"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="w-full bg-white/50 border-2 border-slate-100 rounded-2xl py-4 pl-12 pr-4 text-[16px] font-serif font-bold text-[#757575] focus:outline-none focus:border-[#757575] transition-all bg-opacity-40 focus:bg-white"
              required
            />
          </div>

          <div className="relative group">
            <div className="absolute left-4 top-1/2 -translate-y-1/2 text-[#a0a09c] group-focus-within:text-[#757575] transition-colors">
              <Phone size={20} />
            </div>
            <input
              type="tel"
              placeholder="Số điện thoại"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
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

          <div className="relative group">
            <div className="absolute left-4 top-1/2 -translate-y-1/2 text-[#a0a09c] group-focus-within:text-[#757575] transition-colors">
              <Lock size={20} />
            </div>
            <input
              type="password"
              placeholder="Xác nhận mật khẩu"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
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
            {isLoading ? 'Đang đăng ký...' : 'Hoàn tất'} <ArrowRight size={20} />
          </button>
        </div>
      </form>

      {/* Footer */}
      <div className="mt-auto text-center pb-8 sticky bottom-0">
        <button
          onClick={onSwitchToLogin}
          className="text-[16px] font-serif text-[#a0a09c] hover:text-[#757575] transition-colors"
        >
          Đã có tài khoản? <span className="font-bold">Đăng nhập ngay</span>
        </button>
      </div>
    </div>
  );
};
