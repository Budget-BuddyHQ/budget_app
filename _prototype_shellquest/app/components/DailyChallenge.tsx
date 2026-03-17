import { Trophy } from 'lucide-react';

export function DailyChallenge() {
  return (
    <div>
      <h2 className="text-sm text-gray-300 mb-3">Daily Challenge</h2>
      <div className="bg-gradient-to-r from-[#2d6b54] to-[#1e4d3d] border border-[#3d7b64] rounded-lg p-4 text-white">
        <div className="flex items-center gap-2 mb-3">
          <Trophy className="w-6 h-6 text-[#86efac]" />
          <h3 className="text-xl">THE BUDGET BATTLE</h3>
        </div>
        <p className="text-sm mb-3 text-gray-200">Analyze this $50 Grocery Receipt and find 3 savings.</p>
        <div className="flex gap-2">
          <button className="flex-1 bg-[#86efac] text-[#1e4d3d] rounded-lg py-2 px-4 text-sm hover:bg-[#4ade80]">
            Start Challenge
          </button>
          <button className="px-4 py-2 border border-white/30 rounded-lg text-sm hover:bg-white/10">
            Skip
          </button>
        </div>
      </div>
    </div>
  );
}