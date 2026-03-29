import React from 'react';

export function TurtleAvatar({ className = 'w-14 h-14' }: { className?: string }) {
  return (
    <div
      className={`relative rounded-full bg-gradient-to-br from-[#1b5e20] to-[#0a2916] border-2 border-[#85efac] shadow-[0_0_15px_rgba(133,239,172,0.5)] flex items-center justify-center overflow-hidden ${className}`}
    >
      <svg
        viewBox="0 0 100 100"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-[80%] h-[80%]"
      >
        {/* Wizard Hat */}
        <path
          d="M 50 10 L 30 40 L 70 40 Z"
          fill="#4a148c"
          stroke="#85efac"
          strokeWidth="2"
        />
        <path
          d="M 20 40 L 80 40"
          stroke="#85efac"
          strokeWidth="4"
          strokeLinecap="round"
        />
        
        {/* Turtle Head */}
        <circle cx="50" cy="55" r="15" fill="#2e7d32" stroke="#85efac" strokeWidth="2" />
        
        {/* Eyes */}
        <circle cx="45" cy="50" r="3" fill="#85efac" />
        <circle cx="55" cy="50" r="3" fill="#85efac" />
        
        {/* Smile */}
        <path
          d="M 45 60 Q 50 65 55 60"
          stroke="#85efac"
          strokeWidth="2"
          strokeLinecap="round"
        />
        
        {/* Shell Back / Shoulders */}
        <path
          d="M 20 85 C 20 65, 80 65, 80 85"
          fill="#1b5e20"
          stroke="#85efac"
          strokeWidth="2"
        />
      </svg>
      {/* Level Badge Overlay */}
      <div className="absolute -bottom-1 -right-1 bg-[#85efac] text-[#062c21] text-[10px] font-bold px-1.5 py-0.5 rounded-full border border-[#062c21]">
        Lvl 12
      </div>
    </div>
  );
}
