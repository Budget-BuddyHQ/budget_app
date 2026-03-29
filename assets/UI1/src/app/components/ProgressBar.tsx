import React from 'react';

export function ProgressBar({
  progress,
  color = '#85efac',
  label,
  showLabel = true,
}: {
  progress: number;
  color?: string;
  label?: string;
  showLabel?: boolean;
}) {
  return (
    <div className="w-full flex flex-col gap-2">
      {showLabel && label && (
        <div className="flex justify-between items-center text-xs font-semibold">
          <span className="text-[#a3b8b0]">{label}</span>
          <span className="text-white">{progress}%</span>
        </div>
      )}
      <div className="h-2 w-full bg-black/40 rounded-full overflow-hidden border border-white/5">
        <div
          className="h-full rounded-full transition-all duration-1000 ease-out"
          style={{
            width: `${progress}%`,
            backgroundColor: color,
            boxShadow: `0 0 10px ${color}`,
          }}
        />
      </div>
    </div>
  );
}
