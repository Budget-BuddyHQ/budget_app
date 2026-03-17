import { Bell, User } from 'lucide-react';

interface HeaderProps {
  username: string;
}

export function Header({ username }: HeaderProps) {
  const userGold = 2450;
  const userLevel = 7;

  return (
    <div className="bg-[#1e4d3d] border-b border-[#2d6b54] px-4 py-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-br from-[#86efac] to-[#4ade80] rounded-full flex items-center justify-center">
            <User className="w-5 h-5 text-[#1e4d3d]" />
          </div>
          <div>
            <div className="text-lg text-white">Current Balance: ${userGold}</div>
            <div className="text-sm text-gray-300">Level {userLevel} Finance Wizard</div>
          </div>
        </div>
        <button className="p-2 hover:bg-[#2d6b54] rounded-full">
          <Bell className="w-6 h-6 text-gray-300" />
        </button>
      </div>
    </div>
  );
}