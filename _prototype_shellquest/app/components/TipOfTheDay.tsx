import { Lightbulb } from 'lucide-react';

export function TipOfTheDay() {
  return (
    <div className="bg-gradient-to-r from-[#2d6b54] to-[#1e4d3d] border border-[#3d7b64] rounded-lg p-4">
      <div className="flex items-start gap-3">
        <div className="bg-[#86efac] rounded-full p-2 mt-1">
          <Lightbulb className="w-5 h-5 text-[#1e4d3d]" />
        </div>
        <div className="flex-1">
          <h3 className="text-sm text-gray-300 mb-2">Daily Budget Insight</h3>
          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-3 mb-2">
            <img 
              src="https://images.unsplash.com/photo-1579621970588-a35d0e7ab9b6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmaW5hbmNpYWwlMjBncm93dGglMjBzYXZpbmdzJTIwbW9uZXl8ZW58MXx8fHwxNzczNzA2OTA2fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
              alt="Financial insight illustration" 
              className="w-full h-32 object-cover rounded"
            />
          </div>
          <p className="text-sm text-gray-200">
            A penny saved is a penny earned—Invest $10 today for a 5% gain!
          </p>
        </div>
      </div>
    </div>
  );
}