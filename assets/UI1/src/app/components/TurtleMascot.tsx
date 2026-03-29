interface TurtleMascotProps {
  variant?: 'default' | 'happy' | 'celebrating' | 'sleeping' | 'thinking' | 'excited';
  size?: number;
  className?: string;
}

export function TurtleMascot({ variant = 'default', size = 80, className = '' }: TurtleMascotProps) {
  const renderTurtle = () => {
    switch (variant) {
      case 'happy':
        return (
          <svg width={size} height={size} viewBox="0 0 100 100" className={className}>
            {/* Shell */}
            <ellipse cx="50" cy="55" rx="35" ry="25" fill="#86efac" opacity="0.3" />
            <ellipse cx="50" cy="52" rx="32" ry="23" fill="#6b9d7a" />
            {/* Shell pattern */}
            <path d="M 35 45 Q 40 40 45 45 T 55 45 T 65 45" fill="none" stroke="#4a6b54" strokeWidth="2" />
            <circle cx="40" cy="55" r="4" fill="#4a6b54" />
            <circle cx="50" cy="57" r="4" fill="#4a6b54" />
            <circle cx="60" cy="55" r="4" fill="#4a6b54" />
            
            {/* Bitcoin on shell */}
            <circle cx="50" cy="40" r="10" fill="#f7931a" />
            <text x="50" y="46" fontSize="12" fontWeight="bold" fill="#fff" textAnchor="middle">₿</text>
            
            {/* Head - smiling */}
            <ellipse cx="30" cy="35" rx="10" ry="8" fill="#7ca888" />
            {/* Happy eyes */}
            <circle cx="27" cy="33" r="2" fill="#1e4d3d" />
            <circle cx="33" cy="33" r="2" fill="#1e4d3d" />
            {/* Big smile */}
            <path d="M 25 37 Q 30 40 35 37" fill="none" stroke="#1e4d3d" strokeWidth="1.5" strokeLinecap="round" />
            
            {/* Legs */}
            <ellipse cx="25" cy="65" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="40" cy="68" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="60" cy="68" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="75" cy="65" rx="6" ry="4" fill="#7ca888" />
            
            {/* Tail */}
            <ellipse cx="78" cy="50" rx="5" ry="3" fill="#7ca888" />
          </svg>
        );

      case 'celebrating':
        return (
          <svg width={size} height={size} viewBox="0 0 100 100" className={className}>
            {/* Confetti */}
            <circle cx="20" cy="15" r="2" fill="#86efac" />
            <circle cx="80" cy="20" r="2" fill="#fbbf24" />
            <rect x="35" y="10" width="3" height="3" fill="#ef4444" />
            <rect x="70" y="12" width="3" height="3" fill="#86efac" />
            
            {/* Shell */}
            <ellipse cx="50" cy="55" rx="35" ry="25" fill="#86efac" opacity="0.3" />
            <ellipse cx="50" cy="52" rx="32" ry="23" fill="#6b9d7a" />
            <path d="M 35 45 Q 40 40 45 45 T 55 45 T 65 45" fill="none" stroke="#4a6b54" strokeWidth="2" />
            <circle cx="40" cy="55" r="4" fill="#4a6b54" />
            <circle cx="50" cy="57" r="4" fill="#4a6b54" />
            <circle cx="60" cy="55" r="4" fill="#4a6b54" />
            
            {/* Bitcoin with sparkle */}
            <circle cx="50" cy="40" r="10" fill="#f7931a" />
            <text x="50" y="46" fontSize="12" fontWeight="bold" fill="#fff" textAnchor="middle">₿</text>
            <circle cx="62" cy="35" r="1.5" fill="#fbbf24" />
            <circle cx="58" cy="30" r="1" fill="#fbbf24" />
            
            {/* Head - excited */}
            <ellipse cx="30" cy="32" rx="10" ry="8" fill="#7ca888" />
            {/* Excited eyes */}
            <circle cx="27" cy="30" r="2.5" fill="#1e4d3d" />
            <circle cx="33" cy="30" r="2.5" fill="#1e4d3d" />
            <circle cx="27" cy="30" r="1" fill="#fff" />
            <circle cx="33" cy="30" r="1" fill="#fff" />
            {/* Open mouth smile */}
            <ellipse cx="30" cy="37" rx="3" ry="2" fill="#1e4d3d" />
            
            {/* Legs - one raised */}
            <ellipse cx="25" cy="65" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="40" cy="68" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="60" cy="68" rx="6" ry="4" fill="#7ca888" />
            {/* Raised leg */}
            <ellipse cx="72" cy="60" rx="6" ry="4" fill="#7ca888" transform="rotate(-20 72 60)" />
            
            <ellipse cx="78" cy="50" rx="5" ry="3" fill="#7ca888" />
          </svg>
        );

      case 'sleeping':
        return (
          <svg width={size} height={size} viewBox="0 0 100 100" className={className}>
            {/* Shell */}
            <ellipse cx="50" cy="55" rx="35" ry="25" fill="#86efac" opacity="0.3" />
            <ellipse cx="50" cy="52" rx="32" ry="23" fill="#6b9d7a" />
            <path d="M 35 45 Q 40 40 45 45 T 55 45 T 65 45" fill="none" stroke="#4a6b54" strokeWidth="2" />
            <circle cx="40" cy="55" r="4" fill="#4a6b54" />
            <circle cx="50" cy="57" r="4" fill="#4a6b54" />
            <circle cx="60" cy="55" r="4" fill="#4a6b54" />
            
            {/* Bitcoin */}
            <circle cx="50" cy="40" r="10" fill="#f7931a" />
            <text x="50" y="46" fontSize="12" fontWeight="bold" fill="#fff" textAnchor="middle">₿</text>
            
            {/* Head - tucked in */}
            <ellipse cx="32" cy="42" rx="9" ry="7" fill="#7ca888" />
            {/* Closed eyes */}
            <path d="M 28 40 Q 30 42 32 40" fill="none" stroke="#1e4d3d" strokeWidth="1.5" strokeLinecap="round" />
            <path d="M 32 40 Q 34 42 36 40" fill="none" stroke="#1e4d3d" strokeWidth="1.5" strokeLinecap="round" />
            
            {/* ZZZ */}
            <text x="15" y="25" fontSize="10" fill="#86efac" opacity="0.6">Z</text>
            <text x="12" y="18" fontSize="8" fill="#86efac" opacity="0.4">Z</text>
            <text x="10" y="12" fontSize="6" fill="#86efac" opacity="0.2">Z</text>
            
            {/* Legs */}
            <ellipse cx="30" cy="65" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="42" cy="68" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="58" cy="68" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="70" cy="65" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="75" cy="52" rx="5" ry="3" fill="#7ca888" />
          </svg>
        );

      case 'thinking':
        return (
          <svg width={size} height={size} viewBox="0 0 100 100" className={className}>
            {/* Shell */}
            <ellipse cx="50" cy="55" rx="35" ry="25" fill="#86efac" opacity="0.3" />
            <ellipse cx="50" cy="52" rx="32" ry="23" fill="#6b9d7a" />
            <path d="M 35 45 Q 40 40 45 45 T 55 45 T 65 45" fill="none" stroke="#4a6b54" strokeWidth="2" />
            <circle cx="40" cy="55" r="4" fill="#4a6b54" />
            <circle cx="50" cy="57" r="4" fill="#4a6b54" />
            <circle cx="60" cy="55" r="4" fill="#4a6b54" />
            
            {/* Bitcoin */}
            <circle cx="50" cy="40" r="10" fill="#f7931a" />
            <text x="50" y="46" fontSize="12" fontWeight="bold" fill="#fff" textAnchor="middle">₿</text>
            
            {/* Head - looking up */}
            <ellipse cx="30" cy="38" rx="10" ry="8" fill="#7ca888" />
            {/* Thinking eyes looking up */}
            <circle cx="28" cy="36" r="2" fill="#1e4d3d" />
            <circle cx="32" cy="36" r="2" fill="#1e4d3d" />
            {/* Small mouth */}
            <ellipse cx="30" cy="41" rx="2" ry="1" fill="#1e4d3d" />
            
            {/* Thought bubble */}
            <circle cx="15" cy="20" r="8" fill="#fff" opacity="0.9" />
            <circle cx="20" cy="27" r="3" fill="#fff" opacity="0.9" />
            <circle cx="22" cy="32" r="2" fill="#fff" opacity="0.9" />
            {/* Dollar sign in thought */}
            <text x="15" y="24" fontSize="8" fill="#1e4d3d" textAnchor="middle">$</text>
            
            {/* Legs */}
            <ellipse cx="25" cy="65" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="40" cy="68" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="60" cy="68" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="75" cy="65" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="78" cy="50" rx="5" ry="3" fill="#7ca888" />
          </svg>
        );

      case 'excited':
        return (
          <svg width={size} height={size} viewBox="0 0 100 100" className={className}>
            {/* Shell - bouncing */}
            <ellipse cx="50" cy="53" rx="35" ry="25" fill="#86efac" opacity="0.3" />
            <ellipse cx="50" cy="50" rx="32" ry="23" fill="#6b9d7a" />
            <path d="M 35 43 Q 40 38 45 43 T 55 43 T 65 43" fill="none" stroke="#4a6b54" strokeWidth="2" />
            <circle cx="40" cy="53" r="4" fill="#4a6b54" />
            <circle cx="50" cy="55" r="4" fill="#4a6b54" />
            <circle cx="60" cy="53" r="4" fill="#4a6b54" />
            
            {/* Bitcoin glowing */}
            <circle cx="50" cy="38" r="12" fill="#f7931a" opacity="0.3" />
            <circle cx="50" cy="38" r="10" fill="#f7931a" />
            <text x="50" y="44" fontSize="12" fontWeight="bold" fill="#fff" textAnchor="middle">₿</text>
            
            {/* Head - very excited */}
            <ellipse cx="28" cy="30" rx="11" ry="9" fill="#7ca888" />
            {/* Star eyes */}
            <text x="25" y="32" fontSize="6" fill="#fbbf24">★</text>
            <text x="31" y="32" fontSize="6" fill="#fbbf24">★</text>
            {/* Wide smile */}
            <path d="M 22 34 Q 28 38 34 34" fill="none" stroke="#1e4d3d" strokeWidth="2" strokeLinecap="round" />
            
            {/* Exclamation marks */}
            <text x="70" y="25" fontSize="14" fill="#86efac" fontWeight="bold">!</text>
            <text x="10" y="28" fontSize="14" fill="#fbbf24" fontWeight="bold">!</text>
            
            {/* Legs */}
            <ellipse cx="25" cy="65" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="40" cy="68" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="60" cy="68" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="75" cy="65" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="78" cy="50" rx="5" ry="3" fill="#7ca888" />
          </svg>
        );

      default: // default
        return (
          <svg width={size} height={size} viewBox="0 0 100 100" className={className}>
            {/* Shell shadow */}
            <ellipse cx="50" cy="55" rx="35" ry="25" fill="#86efac" opacity="0.3" />
            {/* Shell */}
            <ellipse cx="50" cy="52" rx="32" ry="23" fill="#6b9d7a" />
            {/* Shell pattern */}
            <path d="M 35 45 Q 40 40 45 45 T 55 45 T 65 45" fill="none" stroke="#4a6b54" strokeWidth="2" />
            <circle cx="40" cy="55" r="4" fill="#4a6b54" />
            <circle cx="50" cy="57" r="4" fill="#4a6b54" />
            <circle cx="60" cy="55" r="4" fill="#4a6b54" />
            
            {/* Bitcoin symbol on shell */}
            <circle cx="50" cy="40" r="10" fill="#f7931a" />
            <text x="50" y="46" fontSize="12" fontWeight="bold" fill="#fff" textAnchor="middle">₿</text>
            
            {/* Head */}
            <ellipse cx="30" cy="35" rx="10" ry="8" fill="#7ca888" />
            {/* Eyes */}
            <circle cx="27" cy="34" r="2" fill="#1e4d3d" />
            <circle cx="33" cy="34" r="2" fill="#1e4d3d" />
            {/* Mouth */}
            <path d="M 26 38 L 34 38" stroke="#1e4d3d" strokeWidth="1" strokeLinecap="round" />
            
            {/* Legs */}
            <ellipse cx="25" cy="65" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="40" cy="68" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="60" cy="68" rx="6" ry="4" fill="#7ca888" />
            <ellipse cx="75" cy="65" rx="6" ry="4" fill="#7ca888" />
            
            {/* Tail */}
            <ellipse cx="78" cy="50" rx="5" ry="3" fill="#7ca888" />
          </svg>
        );
    }
  };

  return renderTurtle();
}
