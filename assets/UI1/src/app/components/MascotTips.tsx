import { TurtleMascot } from './TurtleMascot';
import { useState } from 'react';
import { ChevronRight, ChevronLeft } from 'lucide-react';

const tips = [
  {
    id: 1,
    variant: 'thinking' as const,
    tip: "The 50/30/20 rule: 50% needs, 30% wants, 20% savings. Start small!",
    category: 'Budgeting',
  },
  {
    id: 2,
    variant: 'happy' as const,
    tip: "Compound interest is your friend! Even $10/week adds up over time.",
    category: 'Investing',
  },
  {
    id: 3,
    variant: 'excited' as const,
    tip: "Track every expense for one month. You'll be surprised what you find!",
    category: 'Tracking',
  },
  {
    id: 4,
    variant: 'default' as const,
    tip: "Build an emergency fund of 3-6 months expenses. Peace of mind is priceless!",
    category: 'Savings',
  },
];

export function MascotTips() {
  const [currentTip, setCurrentTip] = useState(0);

  const nextTip = () => {
    setCurrentTip((prev) => (prev + 1) % tips.length);
  };

  const prevTip = () => {
    setCurrentTip((prev) => (prev - 1 + tips.length) % tips.length);
  };

  const tip = tips[currentTip];

  return (
    <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 border border-white/20">
      {/* Header */}
      <div className="flex items-center gap-3 mb-4">
        <TurtleMascot variant={tip.variant} size={70} />
        <div className="flex-1">
          <h3 className="text-lg font-bold text-white">Buddy's Tip</h3>
          <span className="inline-block px-2 py-1 bg-[#86efac]/20 text-[#86efac] text-xs rounded-full mt-1">
            {tip.category}
          </span>
        </div>
      </div>

      {/* Tip content */}
      <div className="bg-white/5 rounded-xl p-4 mb-4 border border-white/10">
        <p className="text-white/90 text-sm leading-relaxed">{tip.tip}</p>
      </div>

      {/* Navigation */}
      <div className="flex items-center justify-between">
        <button
          onClick={prevTip}
          className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors"
          aria-label="Previous tip"
        >
          <ChevronLeft size={16} className="text-white" />
        </button>

        <div className="flex gap-1.5">
          {tips.map((_, index) => (
            <div
              key={index}
              className={`h-1.5 rounded-full transition-all ${
                index === currentTip
                  ? 'w-6 bg-[#86efac]'
                  : 'w-1.5 bg-white/30'
              }`}
            />
          ))}
        </div>

        <button
          onClick={nextTip}
          className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors"
          aria-label="Next tip"
        >
          <ChevronRight size={16} className="text-white" />
        </button>
      </div>
    </div>
  );
}
