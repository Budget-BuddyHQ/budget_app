import React from 'react';

export function GlassCard({
  children,
  className = '',
  glowingBorder = true,
}: {
  children: React.ReactNode;
  className?: string;
  glowingBorder?: boolean;
}) {
  return (
    <div
      className={`
        bg-white/5 backdrop-blur-md 
        rounded-[20px] 
        ${
          glowingBorder
            ? 'border border-[#85efac] shadow-[0_0_15px_rgba(133,239,172,0.15)]'
            : 'border border-white/10 shadow-lg'
        }
        p-5 
        ${className}
      `}
    >
      {children}
    </div>
  );
}
