import { TurtleMascot } from './TurtleMascot';

interface MascotEmptyStateProps {
  title: string;
  message: string;
  actionLabel?: string;
  onAction?: () => void;
  variant?: 'sleeping' | 'thinking' | 'default';
}

export function MascotEmptyState({
  title,
  message,
  actionLabel,
  onAction,
  variant = 'sleeping',
}: MascotEmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-6 text-center">
      {/* Mascot */}
      <TurtleMascot variant={variant} size={120} />

      {/* Title */}
      <h3 className="text-xl font-bold text-white mt-6">{title}</h3>

      {/* Message */}
      <p className="text-white/70 mt-2 max-w-xs">{message}</p>

      {/* Action button */}
      {actionLabel && onAction && (
        <button
          onClick={onAction}
          className="mt-6 px-6 py-3 bg-[#86efac] text-[#1e4d3d] font-semibold rounded-xl hover:bg-[#9ff3ba] transition-colors"
        >
          {actionLabel}
        </button>
      )}
    </div>
  );
}
