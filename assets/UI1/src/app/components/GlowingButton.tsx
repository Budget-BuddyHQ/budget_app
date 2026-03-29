import React from 'react';

export function GlowingButton({
  children,
  onClick,
  className = '',
}: {
  children: React.ReactNode;
  onClick?: () => void;
  className?: string;
}) {
  return (
    <button
      onClick={onClick}
      className={`
        relative w-full py-3 px-6 rounded-xl font-bold text-lg
        bg-gradient-to-b from-[#bbf7d0] to-[#4ade80] text-[#062c21]
        shadow-[0_6px_0_#166534,0_12px_20px_rgba(133,239,172,0.4)]
        active:shadow-[0_0px_0_#166534,0_0px_0px_rgba(133,239,172,0)]
        active:translate-y-[6px]
        border border-white/50
        transition-all duration-150 ease-out
        overflow-hidden
        ${className}
      `}
    >
      {/* 3D Glass Sheen Overlay */}
      <div className="absolute inset-0 bg-gradient-to-b from-white/40 via-white/5 to-transparent h-[40%] rounded-t-xl pointer-events-none" />
      
      {/* 3D Inner Shadow for depth */}
      <div className="absolute inset-0 shadow-[inset_0_-2px_6px_rgba(0,0,0,0.3),inset_0_2px_4px_rgba(255,255,255,0.8)] rounded-xl pointer-events-none" />

      {/* Button Content */}
      <div className="relative flex items-center justify-center gap-2 drop-shadow-[0_2px_1px_rgba(255,255,255,0.5)] z-10">
        {children}
      </div>
    </button>
  );
}
