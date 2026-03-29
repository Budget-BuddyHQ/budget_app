import { TurtleMascot } from './TurtleMascot';
import { Sparkles } from 'lucide-react';

interface MotivationMessage {
  message: string;
  variant: 'happy' | 'celebrating' | 'excited';
}

const motivations: MotivationMessage[] = [
  {
    message: "You're doing great! Keep up the savings streak! 🎯",
    variant: 'happy',
  },
  {
    message: "Wow! You've saved $250 this month! That's amazing! 🌟",
    variant: 'celebrating',
  },
  {
    message: "5 days under budget! You're on fire! 🔥",
    variant: 'excited',
  },
];

export function MascotMotivation() {
  // In a real app, this would be based on user achievements
  const currentMotivation = motivations[1];

  return (
    <div className="bg-gradient-to-br from-[#86efac]/20 to-transparent backdrop-blur-md rounded-2xl p-6 border border-[#86efac]/30 relative overflow-hidden">
      {/* Background decoration */}
      <div className="absolute top-0 right-0 w-32 h-32 bg-[#86efac]/10 rounded-full blur-3xl" />
      
      {/* Content */}
      <div className="relative flex items-start gap-4">
        {/* Animated mascot */}
        <div className="animate-pulse">
          <TurtleMascot variant={currentMotivation.variant} size={80} />
        </div>

        <div className="flex-1 pt-2">
          <div className="flex items-center gap-2 mb-2">
            <Sparkles size={16} className="text-[#86efac]" />
            <span className="text-xs font-semibold text-[#86efac] uppercase tracking-wide">
              Keep it up!
            </span>
          </div>
          <p className="text-white font-medium leading-relaxed">
            {currentMotivation.message}
          </p>
        </div>
      </div>
    </div>
  );
}
