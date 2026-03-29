import { TurtleMascot } from './TurtleMascot';
import { Trophy, Star, TrendingUp, Coins } from 'lucide-react';

interface Achievement {
  id: string;
  title: string;
  description: string;
  icon: 'trophy' | 'star' | 'trending' | 'coins';
  earned: boolean;
}

const achievements: Achievement[] = [
  {
    id: '1',
    title: 'First $100 Saved!',
    description: 'You saved your first $100',
    icon: 'coins',
    earned: true,
  },
  {
    id: '2',
    title: 'Budget Master',
    description: 'Stay under budget for 7 days',
    icon: 'star',
    earned: true,
  },
  {
    id: '3',
    title: 'Investment Pro',
    description: 'Complete 5 investment lessons',
    icon: 'trending',
    earned: false,
  },
  {
    id: '4',
    title: 'Finance Wizard',
    description: 'Reach Level 10',
    icon: 'trophy',
    earned: false,
  },
];

export function MascotAchievement() {
  const getIcon = (iconType: Achievement['icon']) => {
    const iconProps = { size: 20, className: 'text-[#86efac]' };
    switch (iconType) {
      case 'trophy':
        return <Trophy {...iconProps} />;
      case 'star':
        return <Star {...iconProps} />;
      case 'trending':
        return <TrendingUp {...iconProps} />;
      case 'coins':
        return <Coins {...iconProps} />;
    }
  };

  return (
    <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 border border-white/20">
      {/* Header with celebrating mascot */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-xl font-bold text-white">Achievements</h2>
          <p className="text-sm text-white/70">Your progress milestones</p>
        </div>
        <TurtleMascot variant="celebrating" size={60} />
      </div>

      {/* Achievement list */}
      <div className="space-y-3">
        {achievements.map((achievement) => (
          <div
            key={achievement.id}
            className={`flex items-center gap-3 p-3 rounded-xl transition-all ${
              achievement.earned
                ? 'bg-[#86efac]/20 border border-[#86efac]/30'
                : 'bg-white/5 border border-white/10 opacity-60'
            }`}
          >
            <div
              className={`w-10 h-10 rounded-full flex items-center justify-center ${
                achievement.earned ? 'bg-[#86efac]/30' : 'bg-white/10'
              }`}
            >
              {getIcon(achievement.icon)}
            </div>
            <div className="flex-1">
              <h3 className="font-semibold text-white text-sm">
                {achievement.title}
              </h3>
              <p className="text-xs text-white/60">{achievement.description}</p>
            </div>
            {achievement.earned && (
              <div className="text-[#86efac]">
                <Star size={16} fill="#86efac" />
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
