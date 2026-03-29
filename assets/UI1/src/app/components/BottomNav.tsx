import { Home, Target, TrendingUp, User, Award } from 'lucide-react';

export function BottomNav() {
  const navItems = [
    { icon: Home, label: 'Home', active: true },
    { icon: Target, label: 'Budget', active: false },
    { icon: TrendingUp, label: 'Invest', active: false },
    { icon: Award, label: 'Challenges', active: false },
    { icon: User, label: 'Profile', active: false },
  ];

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-[#1e4d3d] border-t border-[#2d6b54] shadow-lg">
      <div className="max-w-md mx-auto">
        <div className="flex justify-around items-center py-2">
          {navItems.map((item) => (
            <button
              key={item.label}
              className={`flex flex-col items-center gap-1 px-4 py-2 ${
                item.active ? 'text-[#86efac]' : 'text-gray-400'
              }`}
            >
              <item.icon className="w-6 h-6" />
              <span className="text-xs">{item.label}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}