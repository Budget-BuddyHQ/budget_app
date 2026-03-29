import React from 'react';
import { LucideIcon } from 'lucide-react';

interface ThreeDIconProps {
  Icon: LucideIcon;
  colorTheme?: 'emerald' | 'lime' | 'purple' | 'dark';
  className?: string;
  iconClassName?: string;
}

export function ThreeDIcon({ Icon, colorTheme = 'emerald', className = '', iconClassName = '' }: ThreeDIconProps) {
  const themes = {
    emerald: {
      bg: 'from-[#10b981] to-[#047857]',
      shadow: 'shadow-[4px_6px_0_#022c22]',
      border: 'border-[#34d399]/30',
      iconText: 'text-white',
    },
    lime: {
      bg: 'from-[#bbf7d0] to-[#4ade80]',
      shadow: 'shadow-[4px_6px_0_#166534]',
      border: 'border-white/50',
      iconText: 'text-[#062c21]',
    },
    purple: {
      bg: 'from-[#a78bfa] to-[#6d28d9]',
      shadow: 'shadow-[4px_6px_0_#2e1065]',
      border: 'border-[#c4b5fd]/30',
      iconText: 'text-white',
    },
    dark: {
      bg: 'from-[#1f2937] to-[#030712]',
      shadow: 'shadow-[4px_6px_0_#000000]',
      border: 'border-white/10',
      iconText: 'text-[#85efac]',
    }
  };

  const theme = themes[colorTheme];

  return (
    <div 
      className={`
        relative flex items-center justify-center rounded-2xl 
        bg-gradient-to-br ${theme.bg} 
        border ${theme.border}
        ${theme.shadow}
        transform transition-transform hover:-translate-y-1 hover:shadow-[6px_8px_0_#022c22]
        ${className}
      `}
      style={{
        boxShadow: `inset -2px -2px 6px rgba(0,0,0,0.4), inset 2px 2px 6px rgba(255,255,255,0.3), ${theme.shadow.replace('shadow-[', '').replace(']', '')}`
      }}
    >
      <Icon className={`w-6 h-6 drop-shadow-[0_2px_2px_rgba(0,0,0,0.5)] ${theme.iconText} ${iconClassName}`} />
      
      {/* Glass reflection top highlight */}
      <div className="absolute top-0 left-0 right-0 h-1/2 bg-gradient-to-b from-white/30 to-transparent rounded-t-2xl pointer-events-none" />
    </div>
  );
}
