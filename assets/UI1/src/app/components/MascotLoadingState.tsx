import { TurtleMascot } from './TurtleMascot';

interface MascotLoadingStateProps {
  message?: string;
}

export function MascotLoadingState({ message = 'Loading your financial data...' }: MascotLoadingStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4">
      {/* Animated mascot */}
      <div className="relative">
        <div className="animate-bounce">
          <TurtleMascot variant="happy" size={100} />
        </div>
        {/* Circular spinner around mascot */}
        <div className="absolute inset-0 -m-4">
          <svg className="animate-spin" width="140" height="140" viewBox="0 0 140 140">
            <circle
              cx="70"
              cy="70"
              r="60"
              fill="none"
              stroke="#86efac"
              strokeWidth="3"
              strokeDasharray="20 10"
              opacity="0.3"
            />
          </svg>
        </div>
      </div>

      {/* Loading message */}
      <p className="text-white/80 mt-6 text-center">{message}</p>

      {/* Loading dots */}
      <div className="flex gap-2 mt-4">
        <div className="w-2 h-2 bg-[#86efac] rounded-full animate-pulse" style={{ animationDelay: '0ms' }} />
        <div className="w-2 h-2 bg-[#86efac] rounded-full animate-pulse" style={{ animationDelay: '200ms' }} />
        <div className="w-2 h-2 bg-[#86efac] rounded-full animate-pulse" style={{ animationDelay: '400ms' }} />
      </div>
    </div>
  );
}
