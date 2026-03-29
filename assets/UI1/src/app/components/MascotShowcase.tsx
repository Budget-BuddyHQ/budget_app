import { TurtleMascot } from './TurtleMascot';

export function MascotShowcase() {
  const variants = [
    { variant: 'default' as const, label: 'Default' },
    { variant: 'happy' as const, label: 'Happy' },
    { variant: 'celebrating' as const, label: 'Celebrating' },
    { variant: 'sleeping' as const, label: 'Sleeping' },
    { variant: 'thinking' as const, label: 'Thinking' },
    { variant: 'excited' as const, label: 'Excited' },
  ];

  return (
    <div className="bg-white/10 backdrop-blur-md rounded-2xl p-6 border border-white/20">
      <h2 className="text-xl font-bold text-white mb-6">Meet Budget Buddy!</h2>
      
      <div className="grid grid-cols-3 gap-6">
        {variants.map(({ variant, label }) => (
          <div key={variant} className="flex flex-col items-center">
            <div className="bg-white/5 rounded-xl p-4 border border-white/10 hover:border-[#86efac]/50 transition-colors">
              <TurtleMascot variant={variant} size={80} />
            </div>
            <span className="text-xs text-white/70 mt-2 text-center">{label}</span>
          </div>
        ))}
      </div>

      <div className="mt-6 p-4 bg-[#86efac]/10 rounded-xl border border-[#86efac]/20">
        <p className="text-sm text-white/80 text-center">
          Your trusty companion on the journey to financial freedom! 🐢✨
        </p>
      </div>
    </div>
  );
}
