import { Header } from './components/Header';
import { TipOfTheDay } from './components/TipOfTheDay';
import { ProgressMetrics } from './components/ProgressMetrics';
import { DailyChallenge } from './components/DailyChallenge';
import { ProgressBar } from './components/ProgressBar';
import { Leaderboard } from './components/Leaderboard';
import { BottomNav } from './components/BottomNav';

export default function App() {
  return (
    <div className="min-h-screen bg-[#1e4d3d] pb-20">
      <div className="max-w-md mx-auto bg-[#1e4d3d] min-h-screen">
        <Header username="Username3189" />
        
        <div className="p-4 space-y-6">
          <TipOfTheDay />
          <ProgressMetrics />
          <DailyChallenge />
          <ProgressBar />
          <Leaderboard />
        </div>
        
        <BottomNav />
      </div>
    </div>
  );
}