import React from 'react';
import { GlassCard } from './components/GlassCard';
import { ProgressBar } from './components/ProgressBar';
import { Sparkline } from './components/Sparkline';
import { TurtleAvatar } from './components/TurtleAvatar';
import { GlowingButton } from './components/GlowingButton';
import { ThreeDIcon } from './components/ThreeDIcon';
import turtleBitcoin from 'figma:asset/f0dfd56a541371c704f7587e4add851958a11a86.png';
import {
  Bell,
  Swords,
  Scroll,
  TrendingUp,
  Target,
  Home,
  Trophy,
  User,
  Zap,
  Bitcoin,
  Banknotes,
} from 'lucide-react';

export default function App() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-[#062c21] to-[#0d4032] text-white font-sans overflow-x-hidden pb-24 relative">
      {/* Background Magic Elements */}
      <div className="fixed inset-0 pointer-events-none opacity-20">
        <div className="absolute top-[-10%] left-[-20%] w-[300px] h-[300px] bg-[#85efac] rounded-full mix-blend-screen filter blur-[100px]" />
        <div className="absolute top-[40%] right-[-10%] w-[250px] h-[250px] bg-[#4ade80] rounded-full mix-blend-screen filter blur-[120px]" />
        <div className="absolute bottom-[-10%] left-[20%] w-[200px] h-[200px] bg-[#0d9488] rounded-full mix-blend-screen filter blur-[90px]" />
      </div>

      <div className="max-w-md mx-auto relative z-10 px-4 pt-6">
        
        {/* Header Section */}
        <header className="flex justify-between items-center mb-8">
          <div className="flex items-center gap-4">
            <TurtleAvatar className="w-14 h-14" />
            <div>
              <p className="text-[#a3b8b0] text-sm font-medium drop-shadow-md">Arcane Balance</p>
              <h1 className="text-3xl font-black tracking-tight text-white drop-shadow-[0_4px_4px_rgba(0,0,0,0.5)]">
                <span className="text-[#85efac] mr-1">$</span>4,250<span className="text-xl text-white/70">.00</span>
              </h1>
            </div>
          </div>
          <button className="relative w-12 h-12 flex items-center justify-center bg-gradient-to-br from-white/10 to-white/5 rounded-2xl border border-white/20 backdrop-blur-md shadow-[4px_6px_0_rgba(0,0,0,0.3)] hover:-translate-y-1 hover:shadow-[6px_8px_0_rgba(0,0,0,0.3)] transition-all">
            <Bell className="w-6 h-6 text-[#85efac] drop-shadow-[0_0_5px_rgba(133,239,172,0.8)]" />
            <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 border-2 border-[#062c21] rounded-full animate-pulse shadow-[0_0_10px_red]" />
            <div className="absolute top-0 left-0 right-0 h-1/2 bg-gradient-to-b from-white/20 to-transparent rounded-t-2xl pointer-events-none" />
          </button>
        </header>

        {/* The Budget Battle Highlight Card (3D Feel) */}
        <GlassCard glowingBorder={true} className="mb-6 relative overflow-hidden group shadow-[inset_0_-4px_10px_rgba(0,0,0,0.4),0_10px_20px_rgba(0,0,0,0.5)]">
          <div className="absolute -top-10 -right-10 w-32 h-32 bg-[#85efac]/30 blur-3xl rounded-full group-hover:bg-[#85efac]/40 transition-all duration-700" />
          
          <div className="flex items-start justify-between mb-4 relative z-10">
            <div>
              <div className="flex items-center gap-2 mb-2">
                <ThreeDIcon Icon={Zap} colorTheme="lime" className="w-8 h-8 rounded-lg" iconClassName="w-4 h-4" />
                <span className="text-xs uppercase tracking-widest text-[#85efac] font-black drop-shadow-md">Daily Challenge</span>
              </div>
              <h2 className="text-2xl font-black text-white mb-2 drop-shadow-[0_2px_2px_rgba(0,0,0,0.8)]">The Budget Battle</h2>
              <p className="text-sm text-[#a3b8b0] leading-relaxed font-medium">
                Scan your recent alchemy shop receipt to earn <span className="text-[#85efac] font-black bg-[#062c21]/50 px-2 py-0.5 rounded shadow-inner">+50 EXP</span> and boost your savings armor.
              </p>
            </div>
            <ThreeDIcon Icon={Swords} colorTheme="dark" className="w-14 h-14 shrink-0" iconClassName="w-7 h-7" />
          </div>
          
          <div className="relative z-10 mt-6 pb-2">
            <GlowingButton className="flex items-center justify-center gap-2">
              <Scroll className="w-5 h-5 text-[#062c21] fill-[#062c21]/20" />
              <span>Analyze Receipt</span>
            </GlowingButton>
          </div>
        </GlassCard>

        {/* Crypto/Savings Vault with User Image */}
        <div className="relative mb-8 mt-12">
          {/* Imported 3D Turtle Graphic positioned hovering over the card */}
          <div className="absolute -top-16 right-0 w-36 h-36 z-20 drop-shadow-[0_15px_15px_rgba(0,0,0,0.6)] animate-[bounce_4s_infinite_ease-in-out]">
            <img src={turtleBitcoin} alt="Turtle Bitcoin Bank" className="w-full h-full object-contain" />
          </div>
          
          <GlassCard className="relative overflow-visible shadow-[inset_0_-4px_10px_rgba(0,0,0,0.4),0_10px_20px_rgba(0,0,0,0.5)] bg-gradient-to-tr from-[#062c21]/80 to-[#0f5132]/60 border-t-2 border-l-2 border-[#85efac]/40 border-r-0 border-b-0" glowingBorder={false}>
            <div className="relative z-10 w-[70%]">
              <div className="flex items-center gap-2 mb-2">
                <ThreeDIcon Icon={Bitcoin} colorTheme="purple" className="w-8 h-8 rounded-lg" iconClassName="w-4 h-4" />
                <span className="text-xs uppercase tracking-widest text-[#a78bfa] font-black drop-shadow-md">Crypto Vault</span>
              </div>
              <h2 className="text-xl font-black text-white mb-1 drop-shadow-[0_2px_2px_rgba(0,0,0,0.8)]">Digital Shell Safe</h2>
              <p className="text-sm text-[#a3b8b0] leading-relaxed mb-4 font-medium">
                Your future assets are locked away! <span className="text-white font-bold">+0.004 BTC</span>
              </p>
              
              <button className="bg-gradient-to-br from-[#a78bfa] to-[#6d28d9] text-white px-4 py-2 rounded-lg font-bold text-sm shadow-[0_4px_0_#4c1d95] active:shadow-[0_0px_0_#4c1d95] active:translate-y-[4px] border border-[#c4b5fd]/50 transition-all">
                View Stash
              </button>
            </div>
          </GlassCard>
        </div>

        {/* Stats & Growth Card */}
        <GlassCard className="mb-6 pb-2 shadow-[inset_0_-4px_10px_rgba(0,0,0,0.4),0_10px_20px_rgba(0,0,0,0.5)] border-t border-l border-white/20 border-r-0 border-b-0 bg-white/[0.03]" glowingBorder={false}>
          <div className="flex justify-between items-center mb-2">
            <div className="flex items-center gap-3">
              <ThreeDIcon Icon={TrendingUp} colorTheme="emerald" className="w-10 h-10 rounded-xl" iconClassName="w-5 h-5" />
              <div>
                <h3 className="text-lg font-black text-white drop-shadow-md">Wealth Growth</h3>
                <p className="text-xs text-[#a3b8b0] font-medium">Past 7 Days</p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-sm font-black text-[#85efac] drop-shadow-[0_2px_2px_rgba(0,0,0,0.8)]">+ $350.00</p>
              <p className="text-xs text-[#a3b8b0] font-medium">Total Gained</p>
            </div>
          </div>
          <Sparkline />
        </GlassCard>

        {/* Quests / Progress Bars */}
        <div className="space-y-4 mb-6">
          <h3 className="text-lg font-black text-white flex items-center gap-2 px-1 drop-shadow-md">
            <ThreeDIcon Icon={Target} colorTheme="lime" className="w-8 h-8 rounded-lg" iconClassName="w-4 h-4" />
            Active Quests
          </h3>
          
          <GlassCard glowingBorder={false} className="flex flex-col gap-4 shadow-[inset_0_-4px_10px_rgba(0,0,0,0.4),0_10px_20px_rgba(0,0,0,0.5)] border-t border-l border-white/20 border-r-0 border-b-0 bg-white/[0.03]">
            <ProgressBar 
              progress={75} 
              label="Savings Quest: Epic Mount" 
              color="#85efac" 
            />
            <div className="w-full h-[2px] bg-gradient-to-r from-transparent via-white/10 to-transparent" />
            <ProgressBar 
              progress={40} 
              label="Financial IQ: Advanced Spells" 
              color="#4ade80" 
            />
          </GlassCard>
        </div>

      </div>

      {/* 3D Bottom Navigation */}
      <div className="fixed bottom-0 left-0 right-0 z-50 px-4 pb-6 pt-4 bg-gradient-to-t from-[#021812] via-[#062c21]/90 to-transparent backdrop-blur-md">
        <nav className="max-w-md mx-auto bg-gradient-to-b from-white/10 to-[#062c21] backdrop-blur-xl border-t border-white/20 rounded-3xl p-2 flex justify-between items-center shadow-[0_20px_40px_rgba(0,0,0,0.8),inset_0_2px_10px_rgba(255,255,255,0.1)]">
          <button className="flex flex-col items-center justify-center w-16 h-14 rounded-2xl bg-[#0a3526] shadow-[inset_0_4px_6px_rgba(0,0,0,0.6)] border border-[#0d4032] relative group transition-all">
            <Home className="w-6 h-6 text-[#85efac] drop-shadow-[0_0_8px_rgba(133,239,172,0.8)]" />
            <span className="absolute bottom-1 w-1.5 h-1.5 bg-[#85efac] rounded-full shadow-[0_0_8px_#85efac]"></span>
          </button>
          
          <button className="flex flex-col items-center justify-center w-16 h-14 rounded-2xl text-[#a3b8b0] hover:text-white hover:bg-white/5 transition-colors">
            <Swords className="w-6 h-6 drop-shadow-md" />
          </button>
          
          <div className="w-20 h-20 -mt-12 rounded-full bg-[#021812] p-1.5 flex items-center justify-center border-t-2 border-white/20 shadow-[0_10px_20px_rgba(0,0,0,0.5)]">
            <button className="relative w-full h-full rounded-full bg-gradient-to-br from-[#85efac] to-[#22c55e] flex items-center justify-center shadow-[0_6px_0_#166534,0_10px_20px_rgba(133,239,172,0.5)] active:shadow-[0_0px_0_#166534] active:translate-y-[6px] border border-white/50 transition-all overflow-hidden group">
               <div className="absolute inset-0 bg-gradient-to-b from-white/40 via-white/5 to-transparent h-[40%] rounded-t-full pointer-events-none" />
              <Zap className="relative z-10 w-8 h-8 text-[#021812] fill-[#021812] drop-shadow-[0_2px_1px_rgba(255,255,255,0.6)] group-hover:scale-110 transition-transform" />
            </button>
          </div>
          
          <button className="flex flex-col items-center justify-center w-16 h-14 rounded-2xl text-[#a3b8b0] hover:text-white hover:bg-white/5 transition-colors">
            <Trophy className="w-6 h-6 drop-shadow-md" />
          </button>
          
          <button className="flex flex-col items-center justify-center w-16 h-14 rounded-2xl text-[#a3b8b0] hover:text-white hover:bg-white/5 transition-colors">
            <User className="w-6 h-6 drop-shadow-md" />
          </button>
        </nav>
      </div>
      
    </div>
  );
}
