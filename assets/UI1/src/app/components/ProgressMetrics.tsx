import { PiggyBank, Brain, TrendingUp } from 'lucide-react';

export function ProgressMetrics() {
  return (
    <div>
      <h2 className="text-sm text-gray-300 mb-3">Week's Progress Metrics</h2>
      <div className="grid grid-cols-3 gap-3">
        {/* Savings Rate */}
        <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-lg p-3">
          <div className="text-[#86efac] mb-2">
            <PiggyBank className="w-5 h-5" />
          </div>
          <div className="text-xs text-gray-300 mb-2">Savings Rate</div>
          <div className="w-full bg-white/20 rounded-full h-2 mb-1">
            <div 
              className="bg-[#86efac] h-2 rounded-full transition-all"
              style={{ width: '72%' }}
            />
          </div>
          <div className="text-xs text-gray-200">72% of goal</div>
        </div>

        {/* Knowledge Score */}
        <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-lg p-3">
          <div className="text-[#86efac] mb-2">
            <Brain className="w-5 h-5" />
          </div>
          <div className="text-lg text-white">850</div>
          <div className="text-xs text-gray-300">Literacy Points</div>
          <div className="text-xs text-gray-400 mt-1">Knowledge Score</div>
        </div>

        {/* Investment ROI */}
        <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-lg p-3">
          <div className="text-[#86efac] mb-2">
            <TrendingUp className="w-5 h-5" />
          </div>
          <div className="text-lg text-white">+12.5%</div>
          <div className="text-xs text-gray-300">This Month</div>
          <div className="text-xs text-gray-400 mt-1">Investment ROI</div>
          <svg className="w-full h-6 mt-1" viewBox="0 0 60 20">
            <polyline
              points="0,15 10,12 20,14 30,8 40,10 50,5 60,3"
              fill="none"
              stroke="#86efac"
              strokeWidth="2"
            />
          </svg>
        </div>
      </div>
    </div>
  );
}
