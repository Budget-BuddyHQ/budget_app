export function MascotGallery() {
  return (
    <div className="min-h-screen bg-[#1e4d3d] p-4">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-2xl font-bold text-white mb-6 text-center">Budget Buddy Mascot Gallery</h1>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          {/* Each mascot illustration */}
          <MascotCard>
            <TurtleWithCoin />
          </MascotCard>
          
          <MascotCard>
            <TurtleWithChart />
          </MascotCard>
          
          <MascotCard>
            <TurtleWithPiggyBank />
          </MascotCard>
          
          <MascotCard>
            <TurtleWithCalculator />
          </MascotCard>
          
          <MascotCard>
            <TurtleWithMoney />
          </MascotCard>
          
          <MascotCard>
            <TurtleWithWallet />
          </MascotCard>
          
          <MascotCard>
            <TurtleWizard />
          </MascotCard>
          
          <MascotCard>
            <TurtleSuperhero />
          </MascotCard>
          
          <MascotCard>
            <TurtleProfessor />
          </MascotCard>
          
          <MascotCard>
            <TurtleWithTrophy />
          </MascotCard>
          
          <MascotCard>
            <TurtleWithRocket />
          </MascotCard>
          
          <MascotCard>
            <TurtleRelaxing />
          </MascotCard>
        </div>
      </div>
    </div>
  );
}

function MascotCard({ children }: { children: React.ReactNode }) {
  return (
    <div className="bg-white/10 backdrop-blur-md rounded-2xl p-4 border border-white/20 hover:border-[#86efac]/50 transition-all hover:scale-105">
      {children}
    </div>
  );
}

// Individual Mascot Illustrations

function TurtleWithCoin() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      {/* Background circle */}
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      {/* Shell shadow */}
      <ellipse cx="100" cy="125" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      
      {/* Shell */}
      <ellipse cx="100" cy="120" rx="50" ry="38" fill="#6b9d7a" />
      
      {/* Shell hexagon pattern */}
      <path d="M 80 105 L 90 100 L 100 105 L 100 115 L 90 120 L 80 115 Z" fill="#4a6b54" opacity="0.6" />
      <path d="M 100 105 L 110 100 L 120 105 L 120 115 L 110 120 L 100 115 Z" fill="#4a6b54" opacity="0.6" />
      <circle cx="90" cy="130" r="6" fill="#4a6b54" opacity="0.6" />
      <circle cx="110" cy="130" r="6" fill="#4a6b54" opacity="0.6" />
      
      {/* Large Bitcoin on shell */}
      <circle cx="100" cy="100" r="20" fill="#f7931a" />
      <circle cx="100" cy="100" r="18" fill="none" stroke="#fff" strokeWidth="2" />
      <text x="100" y="110" fontSize="24" fontWeight="bold" fill="#fff" textAnchor="middle">₿</text>
      
      {/* Shine effect */}
      <circle cx="108" cy="92" r="4" fill="#fff" opacity="0.4" />
      
      {/* Head */}
      <ellipse cx="60" cy="90" rx="18" ry="14" fill="#7ca888" />
      
      {/* Eyes - looking at coin */}
      <circle cx="56" cy="88" r="3" fill="#1e4d3d" />
      <circle cx="64" cy="88" r="3" fill="#1e4d3d" />
      <circle cx="57" cy="87" r="1" fill="#fff" />
      <circle cx="65" cy="87" r="1" fill="#fff" />
      
      {/* Happy smile */}
      <path d="M 54 94 Q 60 98 66 94" fill="none" stroke="#1e4d3d" strokeWidth="2" strokeLinecap="round" />
      
      {/* Legs */}
      <ellipse cx="60" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="80" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="120" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="140" cy="145" rx="10" ry="7" fill="#7ca888" />
      
      {/* Tail */}
      <ellipse cx="145" cy="115" rx="8" ry="5" fill="#7ca888" />
      
      {/* Sparkles around coin */}
      <text x="75" y="85" fontSize="12" fill="#fbbf24">★</text>
      <text x="125" y="85" fontSize="12" fill="#fbbf24">★</text>
      <text x="100" y="65" fontSize="10" fill="#fbbf24">✨</text>
    </svg>
  );
}

function TurtleWithChart() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      <ellipse cx="100" cy="125" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      <ellipse cx="100" cy="120" rx="50" ry="38" fill="#6b9d7a" />
      
      {/* Shell pattern */}
      <circle cx="85" cy="115" r="6" fill="#4a6b54" opacity="0.6" />
      <circle cx="100" cy="115" r="6" fill="#4a6b54" opacity="0.6" />
      <circle cx="115" cy="115" r="6" fill="#4a6b54" opacity="0.6" />
      <circle cx="92" cy="128" r="5" fill="#4a6b54" opacity="0.6" />
      <circle cx="108" cy="128" r="5" fill="#4a6b54" opacity="0.6" />
      
      {/* Chart on shell */}
      <rect x="75" y="80" width="50" height="35" fill="#fff" opacity="0.9" rx="4" />
      
      {/* Bar chart */}
      <rect x="82" y="100" width="6" height="10" fill="#86efac" />
      <rect x="92" y="95" width="6" height="15" fill="#86efac" />
      <rect x="102" y="88" width="6" height="22" fill="#86efac" />
      <rect x="112" y="93" width="6" height="17" fill="#86efac" />
      
      {/* Up arrow */}
      <path d="M 110 85 L 115 80 L 120 85" fill="none" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      <line x1="115" y1="80" x2="115" y2="90" stroke="#22c55e" strokeWidth="2" strokeLinecap="round" />
      
      <ellipse cx="60" cy="90" rx="18" ry="14" fill="#7ca888" />
      
      {/* Excited eyes */}
      <circle cx="56" cy="88" r="3.5" fill="#1e4d3d" />
      <circle cx="64" cy="88" r="3.5" fill="#1e4d3d" />
      <circle cx="57" cy="87" r="1.5" fill="#fff" />
      <circle cx="65" cy="87" r="1.5" fill="#fff" />
      
      <path d="M 54 95 Q 60 99 66 95" fill="none" stroke="#1e4d3d" strokeWidth="2" strokeLinecap="round" />
      
      <ellipse cx="60" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="80" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="120" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="140" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="145" cy="115" rx="8" ry="5" fill="#7ca888" />
    </svg>
  );
}

function TurtleWithPiggyBank() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      <ellipse cx="100" cy="125" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      <ellipse cx="100" cy="120" rx="50" ry="38" fill="#6b9d7a" />
      
      <circle cx="85" cy="115" r="6" fill="#4a6b54" opacity="0.6" />
      <circle cx="100" cy="115" r="6" fill="#4a6b54" opacity="0.6" />
      <circle cx="115" cy="115" r="6" fill="#4a6b54" opacity="0.6" />
      
      {/* Piggy bank on shell */}
      <ellipse cx="100" cy="95" rx="18" ry="14" fill="#ffc0cb" />
      <circle cx="100" cy="95" r="12" fill="#ffc0cb" />
      
      {/* Pig features */}
      <circle cx="96" cy="93" r="1.5" fill="#000" />
      <circle cx="104" cy="93" r="1.5" fill="#000" />
      
      {/* Snout */}
      <ellipse cx="100" cy="98" rx="4" ry="3" fill="#ffb3c1" />
      <circle cx="98" cy="98" r="0.8" fill="#000" />
      <circle cx="102" cy="98" r="0.8" fill="#000" />
      
      {/* Coin slot */}
      <rect x="98" y="88" width="4" height="1.5" fill="#ff69b4" />
      
      {/* Coin going in */}
      <circle cx="100" cy="82" r="5" fill="#fbbf24" />
      <text x="100" y="85" fontSize="6" fill="#000" textAnchor="middle">$</text>
      
      {/* Pig legs */}
      <rect x="92" y="102" width="2" height="4" fill="#ffb3c1" rx="1" />
      <rect x="106" y="102" width="2" height="4" fill="#ffb3c1" rx="1" />
      
      <ellipse cx="55" cy="90" rx="18" ry="14" fill="#7ca888" />
      <circle cx="51" cy="88" r="3" fill="#1e4d3d" />
      <circle cx="59" cy="88" r="3" fill="#1e4d3d" />
      <path d="M 50 94 Q 55 97 60 94" fill="none" stroke="#1e4d3d" strokeWidth="2" strokeLinecap="round" />
      
      <ellipse cx="60" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="80" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="120" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="140" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="145" cy="115" rx="8" ry="5" fill="#7ca888" />
    </svg>
  );
}

function TurtleWithCalculator() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      <ellipse cx="100" cy="125" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      <ellipse cx="100" cy="120" rx="50" ry="38" fill="#6b9d7a" />
      
      <circle cx="90" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      <circle cx="110" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      
      {/* Calculator */}
      <rect x="80" y="80" width="40" height="50" fill="#333" rx="3" />
      
      {/* Screen */}
      <rect x="85" y="85" width="30" height="10" fill="#86efac" opacity="0.9" />
      <text x="113" y="93" fontSize="6" fill="#1e4d3d" textAnchor="end" fontFamily="monospace">123.45</text>
      
      {/* Buttons grid */}
      <rect x="86" y="100" width="6" height="5" fill="#666" rx="1" />
      <rect x="94" y="100" width="6" height="5" fill="#666" rx="1" />
      <rect x="102" y="100" width="6" height="5" fill="#666" rx="1" />
      <rect x="110" y="100" width="6" height="5" fill="#86efac" rx="1" />
      
      <rect x="86" y="108" width="6" height="5" fill="#666" rx="1" />
      <rect x="94" y="108" width="6" height="5" fill="#666" rx="1" />
      <rect x="102" y="108" width="6" height="5" fill="#666" rx="1" />
      <rect x="110" y="108" width="6" height="5" fill="#86efac" rx="1" />
      
      <rect x="86" y="116" width="6" height="5" fill="#666" rx="1" />
      <rect x="94" y="116" width="6" height="5" fill="#666" rx="1" />
      <rect x="102" y="116" width="6" height="5" fill="#666" rx="1" />
      <rect x="110" y="116" width="6" height="5" fill="#86efac" rx="1" />
      
      <rect x="86" y="124" width="14" height="5" fill="#fbbf24" rx="1" />
      <rect x="102" y="124" width="6" height="5" fill="#666" rx="1" />
      <rect x="110" y="124" width="6" height="5" fill="#86efac" rx="1" />
      
      {/* Head looking at calculator */}
      <ellipse cx="55" cy="95" rx="18" ry="14" fill="#7ca888" />
      <circle cx="52" cy="93" r="3" fill="#1e4d3d" />
      <circle cx="58" cy="93" r="3" fill="#1e4d3d" />
      <ellipse cx="55" cy="99" rx="2" ry="1.5" fill="#1e4d3d" />
      
      <ellipse cx="60" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="80" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="120" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="140" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="145" cy="115" rx="8" ry="5" fill="#7ca888" />
    </svg>
  );
}

function TurtleWithMoney() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      <ellipse cx="100" cy="125" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      <ellipse cx="100" cy="120" rx="50" ry="38" fill="#6b9d7a" />
      
      <circle cx="90" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      <circle cx="110" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      
      {/* Money bills floating */}
      <g opacity="0.9">
        <rect x="75" y="70" width="25" height="12" fill="#85bb65" rx="2" />
        <circle cx="87.5" cy="76" r="3" fill="#6b9d5a" />
        <text x="87.5" y="78" fontSize="5" fill="#fff" textAnchor="middle">$</text>
      </g>
      
      <g opacity="0.9" transform="rotate(15 110 85)">
        <rect x="98" y="78" width="25" height="12" fill="#85bb65" rx="2" />
        <circle cx="110.5" cy="84" r="3" fill="#6b9d5a" />
        <text x="110.5" y="86" fontSize="5" fill="#fff" textAnchor="middle">$</text>
      </g>
      
      <g opacity="0.9" transform="rotate(-10 90 100)">
        <rect x="78" y="94" width="25" height="12" fill="#85bb65" rx="2" />
        <circle cx="90.5" cy="100" r="3" fill="#6b9d5a" />
        <text x="90.5" y="102" fontSize="5" fill="#fff" textAnchor="middle">$</text>
      </g>
      
      {/* Coins */}
      <circle cx="120" cy="95" r="6" fill="#fbbf24" />
      <circle cx="120" cy="95" r="5" fill="none" stroke="#fff" strokeWidth="0.5" />
      <text x="120" y="98" fontSize="6" fill="#fff" textAnchor="middle">$</text>
      
      <circle cx="112" cy="110" r="5" fill="#fbbf24" />
      <circle cx="112" cy="110" r="4" fill="none" stroke="#fff" strokeWidth="0.5" />
      
      {/* Excited turtle */}
      <ellipse cx="55" cy="90" rx="18" ry="14" fill="#7ca888" />
      <circle cx="51" cy="88" r="4" fill="#1e4d3d" />
      <circle cx="59" cy="88" r="4" fill="#1e4d3d" />
      <circle cx="52" cy="87" r="1.5" fill="#fff" />
      <circle cx="60" cy="87" r="1.5" fill="#fff" />
      <path d="M 49 95 Q 55 100 61 95" fill="none" stroke="#1e4d3d" strokeWidth="2" strokeLinecap="round" />
      
      <ellipse cx="60" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="80" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="120" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="140" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="145" cy="115" rx="8" ry="5" fill="#7ca888" />
    </svg>
  );
}

function TurtleWithWallet() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      <ellipse cx="100" cy="125" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      <ellipse cx="100" cy="120" rx="50" ry="38" fill="#6b9d7a" />
      
      <circle cx="90" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      <circle cx="110" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      
      {/* Wallet */}
      <rect x="80" y="85" width="40" height="30" fill="#8b4513" rx="3" />
      <rect x="80" y="85" width="40" height="5" fill="#654321" rx="3" />
      
      {/* Wallet details */}
      <rect x="85" y="97" width="15" height="10" fill="#85bb65" opacity="0.8" />
      <line x1="107" y1="97" x2="115" y2="97" stroke="#654321" strokeWidth="1" />
      <line x1="107" y1="102" x2="115" y2="102" stroke="#654321" strokeWidth="1" />
      <line x1="107" y1="107" x2="115" y2="107" stroke="#654321" strokeWidth="1" />
      
      {/* Card sticking out */}
      <rect x="82" y="78" width="20" height="12" fill="#4a90e2" rx="2" />
      <rect x="84" y="81" width="16" height="2" fill="#fff" opacity="0.3" />
      
      <ellipse cx="55" cy="95" rx="18" ry="14" fill="#7ca888" />
      <circle cx="51" cy="93" r="3" fill="#1e4d3d" />
      <circle cx="59" cy="93" r="3" fill="#1e4d3d" />
      <path d="M 50 98 Q 55 101 60 98" fill="none" stroke="#1e4d3d" strokeWidth="2" strokeLinecap="round" />
      
      <ellipse cx="60" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="80" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="120" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="140" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="145" cy="115" rx="8" ry="5" fill="#7ca888" />
    </svg>
  );
}

function TurtleWizard() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      {/* Stars in background */}
      <text x="30" y="40" fontSize="12" fill="#fbbf24">★</text>
      <text x="170" y="50" fontSize="10" fill="#fbbf24">★</text>
      <text x="150" y="30" fontSize="8" fill="#86efac">★</text>
      
      <ellipse cx="100" cy="125" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      <ellipse cx="100" cy="120" rx="50" ry="38" fill="#6b9d7a" />
      
      <circle cx="90" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      <circle cx="110" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      
      {/* Wizard hat */}
      <path d="M 50 65 L 65 30 L 80 65 Z" fill="#4b0082" />
      <ellipse cx="65" cy="65" rx="18" ry="5" fill="#4b0082" />
      <circle cx="65" cy="47" r="4" fill="#fbbf24" />
      
      {/* Hat band with stars */}
      <ellipse cx="65" cy="64" rx="17" ry="4" fill="#fbbf24" />
      <text x="58" y="66" fontSize="6" fill="#4b0082">★</text>
      <text x="68" y="66" fontSize="6" fill="#4b0082">★</text>
      
      {/* Head */}
      <ellipse cx="60" cy="80" rx="18" ry="14" fill="#7ca888" />
      
      {/* Wise eyes with glasses */}
      <circle cx="55" cy="78" r="6" fill="#fff" opacity="0.8" />
      <circle cx="65" cy="78" r="6" fill="#fff" opacity="0.8" />
      <circle cx="55" cy="78" r="3" fill="#1e4d3d" />
      <circle cx="65" cy="78" r="3" fill="#1e4d3d" />
      <line x1="61" y1="78" x2="49" y2="78" stroke="#333" strokeWidth="1" />
      <line x1="71" y1="78" x2="61" y2="78" stroke="#333" strokeWidth="1" />
      
      {/* Beard */}
      <ellipse cx="60" cy="90" rx="8" ry="6" fill="#ddd" />
      <path d="M 52 88 Q 60 95 68 88" fill="#ddd" />
      
      {/* Magic wand */}
      <line x1="40" y1="110" x2="25" y2="95" stroke="#8b4513" strokeWidth="2" strokeLinecap="round" />
      <text x="23" y="93" fontSize="14" fill="#fbbf24">✨</text>
      
      {/* Magical sparkles */}
      <circle cx="35" cy="100" r="2" fill="#86efac" opacity="0.7" />
      <circle cx="30" cy="105" r="1.5" fill="#fbbf24" opacity="0.7" />
      
      <ellipse cx="60" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="80" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="120" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="140" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="145" cy="115" rx="8" ry="5" fill="#7ca888" />
    </svg>
  );
}

function TurtleSuperhero() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      {/* Action lines */}
      <line x1="150" y1="70" x2="170" y2="60" stroke="#86efac" strokeWidth="2" opacity="0.5" strokeLinecap="round" />
      <line x1="155" y1="85" x2="175" y2="80" stroke="#86efac" strokeWidth="2" opacity="0.5" strokeLinecap="round" />
      
      <ellipse cx="100" cy="125" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      <ellipse cx="100" cy="120" rx="50" ry="38" fill="#6b9d7a" />
      
      <circle cx="90" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      <circle cx="110" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      
      {/* Cape */}
      <path d="M 95 105 Q 75 110 70 140 L 80 145 L 90 120 Z" fill="#dc2626" />
      <path d="M 105 105 Q 125 110 130 140 L 120 145 L 110 120 Z" fill="#dc2626" />
      
      {/* Dollar sign emblem on shell */}
      <circle cx="100" cy="100" r="15" fill="#fbbf24" />
      <circle cx="100" cy="100" r="13" fill="none" stroke="#fff" strokeWidth="2" />
      <text x="100" y="108" fontSize="20" fontWeight="bold" fill="#fff" textAnchor="middle">$</text>
      
      {/* Mask on head */}
      <ellipse cx="60" cy="85" rx="18" ry="14" fill="#7ca888" />
      <path d="M 45 83 L 52 85 L 68 85 L 75 83" fill="#dc2626" />
      <ellipse cx="60" cy="85" rx="14" ry="4" fill="#dc2626" />
      
      {/* Eyes through mask */}
      <ellipse cx="55" cy="85" rx="4" ry="5" fill="#fff" />
      <ellipse cx="65" cy="85" rx="4" ry="5" fill="#fff" />
      <circle cx="55" cy="85" r="2" fill="#1e4d3d" />
      <circle cx="65" cy="85" r="2" fill="#1e4d3d" />
      
      {/* Determined mouth */}
      <line x1="54" y1="91" x2="66" y2="91" stroke="#1e4d3d" strokeWidth="2" strokeLinecap="round" />
      
      {/* Fist raised */}
      <ellipse cx="35" cy="100" rx="8" ry="10" fill="#7ca888" />
      <circle cx="35" cy="95" r="5" fill="#7ca888" />
      
      <ellipse cx="60" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="80" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="120" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="140" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="145" cy="115" rx="8" ry="5" fill="#7ca888" />
    </svg>
  );
}

function TurtleProfessor() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      <ellipse cx="100" cy="125" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      <ellipse cx="100" cy="120" rx="50" ry="38" fill="#6b9d7a" />
      
      <circle cx="90" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      <circle cx="110" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      
      {/* Graduation cap */}
      <rect x="45" y="55" width="35" height="4" fill="#000" />
      <path d="M 50 55 L 50 45 L 75 45 L 75 55 Z" fill="#000" />
      
      {/* Tassel */}
      <line x1="50" y1="45" x2="45" y2="38" stroke="#fbbf24" strokeWidth="2" strokeLinecap="round" />
      <circle cx="45" cy="36" r="2" fill="#fbbf24" />
      
      {/* Head */}
      <ellipse cx="60" cy="80" rx="18" ry="14" fill="#7ca888" />
      
      {/* Glasses */}
      <circle cx="54" cy="78" r="6" fill="none" stroke="#333" strokeWidth="1.5" />
      <circle cx="66" cy="78" r="6" fill="none" stroke="#333" strokeWidth="1.5" />
      <line x1="60" y1="78" x2="60" y2="78" stroke="#333" strokeWidth="1.5" />
      <line x1="48" y1="78" x2="45" y2="78" stroke="#333" strokeWidth="1" />
      <line x1="72" y1="78" x2="75" y2="78" stroke="#333" strokeWidth="1" />
      
      {/* Eyes behind glasses */}
      <circle cx="54" cy="78" r="2.5" fill="#1e4d3d" />
      <circle cx="66" cy="78" r="2.5" fill="#1e4d3d" />
      
      {/* Smile */}
      <path d="M 54 86 Q 60 89 66 86" fill="none" stroke="#1e4d3d" strokeWidth="1.5" strokeLinecap="round" />
      
      {/* Book/Diploma */}
      <rect x="85" y="90" width="30" height="20" fill="#8b4513" rx="2" />
      <rect x="88" y="93" width="24" height="14" fill="#f5deb3" />
      <line x1="92" y1="96" x2="108" y2="96" stroke="#8b4513" strokeWidth="0.5" />
      <line x1="92" y1="99" x2="108" y2="99" stroke="#8b4513" strokeWidth="0.5" />
      <line x1="92" y1="102" x2="108" y2="102" stroke="#8b4513" strokeWidth="0.5" />
      
      {/* Pointer stick */}
      <line x1="40" y1="110" x2="25" y2="100" stroke="#8b4513" strokeWidth="1.5" strokeLinecap="round" />
      
      <ellipse cx="60" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="80" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="120" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="140" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="145" cy="115" rx="8" ry="5" fill="#7ca888" />
    </svg>
  );
}

function TurtleWithTrophy() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      {/* Confetti */}
      <circle cx="40" cy="40" r="3" fill="#fbbf24" />
      <circle cx="160" cy="45" r="3" fill="#86efac" />
      <circle cx="50" cy="60" r="2" fill="#ef4444" />
      <circle cx="150" cy="55" r="2" fill="#60a5fa" />
      
      <ellipse cx="100" cy="125" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      <ellipse cx="100" cy="120" rx="50" ry="38" fill="#6b9d7a" />
      
      <circle cx="90" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      <circle cx="110" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      
      {/* Trophy */}
      <g>
        {/* Base */}
        <rect x="90" y="108" width="20" height="3" fill="#fbbf24" />
        <rect x="93" y="104" width="14" height="4" fill="#fbbf24" />
        
        {/* Cup */}
        <path d="M 95 85 L 92 104 L 108 104 L 105 85 Z" fill="#fbbf24" />
        
        {/* Handles */}
        <path d="M 92 90 Q 85 90 85 95 Q 85 98 92 98" fill="none" stroke="#fbbf24" strokeWidth="2" />
        <path d="M 108 90 Q 115 90 115 95 Q 115 98 108 98" fill="none" stroke="#fbbf24" strokeWidth="2" />
        
        {/* Shine */}
        <ellipse cx="98" cy="92" rx="2" ry="4" fill="#fff" opacity="0.4" />
        
        {/* Number 1 */}
        <text x="100" y="98" fontSize="12" fontWeight="bold" fill="#fff" textAnchor="middle">1</text>
      </g>
      
      {/* Happy head */}
      <ellipse cx="60" cy="85" rx="18" ry="14" fill="#7ca888" />
      <circle cx="56" cy="83" r="3.5" fill="#1e4d3d" />
      <circle cx="64" cy="83" r="3.5" fill="#1e4d3d" />
      <circle cx="57" cy="82" r="1.5" fill="#fff" />
      <circle cx="65" cy="82" r="1.5" fill="#fff" />
      
      {/* Big happy smile */}
      <path d="M 52 90 Q 60 96 68 90" fill="none" stroke="#1e4d3d" strokeWidth="2.5" strokeLinecap="round" />
      
      <ellipse cx="60" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="80" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="120" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="140" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="145" cy="115" rx="8" ry="5" fill="#7ca888" />
    </svg>
  );
}

function TurtleWithRocket() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      {/* Stars */}
      <text x="30" y="50" fontSize="10" fill="#fbbf24">★</text>
      <text x="170" y="60" fontSize="8" fill="#fbbf24">★</text>
      <text x="160" y="40" fontSize="6" fill="#86efac">★</text>
      
      <ellipse cx="100" cy="125" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      <ellipse cx="100" cy="120" rx="50" ry="38" fill="#6b9d7a" />
      
      <circle cx="90" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      <circle cx="110" cy="120" r="5" fill="#4a6b54" opacity="0.6" />
      
      {/* Rocket */}
      <g>
        {/* Body */}
        <ellipse cx="105" cy="80" rx="10" ry="25" fill="#ef4444" />
        
        {/* Nose cone */}
        <path d="M 95 55 L 105 45 L 115 55 Z" fill="#dc2626" />
        
        {/* Window */}
        <circle cx="105" cy="75" r="5" fill="#60a5fa" opacity="0.8" />
        <circle cx="105" cy="75" r="3" fill="#1e4d3d" opacity="0.3" />
        
        {/* Fins */}
        <path d="M 95 95 L 88 105 L 95 100 Z" fill="#dc2626" />
        <path d="M 115 95 L 122 105 L 115 100 Z" fill="#dc2626" />
        
        {/* Flames */}
        <ellipse cx="105" cy="108" rx="6" ry="8" fill="#fbbf24" />
        <ellipse cx="105" cy="112" rx="4" ry="6" fill="#fb923c" />
        <ellipse cx="105" cy="115" rx="2" ry="4" fill="#ef4444" />
        
        {/* Smoke trail */}
        <circle cx="105" cy="120" r="2" fill="#9ca3af" opacity="0.4" />
        <circle cx="107" cy="125" r="1.5" fill="#9ca3af" opacity="0.3" />
        <circle cx="103" cy="128" r="1" fill="#9ca3af" opacity="0.2" />
      </g>
      
      {/* Arrow going up */}
      <path d="M 130 85 L 135 70 L 140 85" fill="none" stroke="#86efac" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
      <line x1="135" y1="70" x2="135" y2="95" stroke="#86efac" strokeWidth="3" strokeLinecap="round" />
      
      {/* Excited head */}
      <ellipse cx="60" cy="90" rx="18" ry="14" fill="#7ca888" />
      <text x="54" y="92" fontSize="8" fill="#fbbf24">★</text>
      <text x="62" y="92" fontSize="8" fill="#fbbf24">★</text>
      <path d="M 52 97 Q 60 102 68 97" fill="none" stroke="#1e4d3d" strokeWidth="2" strokeLinecap="round" />
      
      <ellipse cx="60" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="80" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="120" cy="150" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="140" cy="145" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="145" cy="115" rx="8" ry="5" fill="#7ca888" />
    </svg>
  );
}

function TurtleRelaxing() {
  return (
    <svg viewBox="0 0 200 200" className="w-full h-auto">
      <circle cx="100" cy="100" r="90" fill="#2a6b4f" opacity="0.3" />
      
      {/* Sun */}
      <circle cx="160" cy="40" r="15" fill="#fbbf24" opacity="0.8" />
      <line x1="160" y1="20" x2="160" y2="25" stroke="#fbbf24" strokeWidth="2" opacity="0.6" strokeLinecap="round" />
      <line x1="180" y1="40" x2="175" y2="40" stroke="#fbbf24" strokeWidth="2" opacity="0.6" strokeLinecap="round" />
      <line x1="172" y1="28" x2="168" y2="32" stroke="#fbbf24" strokeWidth="2" opacity="0.6" strokeLinecap="round" />
      <line x1="172" y1="52" x2="168" y2="48" stroke="#fbbf24" strokeWidth="2" opacity="0.6" strokeLinecap="round" />
      
      <ellipse cx="100" cy="135" rx="55" ry="40" fill="#86efac" opacity="0.2" />
      <ellipse cx="100" cy="130" rx="50" ry="38" fill="#6b9d7a" />
      
      <circle cx="90" cy="128" r="5" fill="#4a6b54" opacity="0.6" />
      <circle cx="110" cy="128" r="5" fill="#4a6b54" opacity="0.6" />
      
      {/* Beach towel under turtle */}
      <rect x="60" y="140" width="80" height="30" fill="#60a5fa" opacity="0.6" rx="3" />
      <line x1="60" y1="150" x2="140" y2="150" stroke="#fff" strokeWidth="2" opacity="0.4" />
      <line x1="60" y1="160" x2="140" y2="160" stroke="#fff" strokeWidth="2" opacity="0.4" />
      
      {/* Sunglasses */}
      <ellipse cx="60" cy="100" rx="18" ry="14" fill="#7ca888" />
      
      <ellipse cx="55" cy="98" rx="6" ry="5" fill="#333" />
      <ellipse cx="65" cy="98" rx="6" ry="5" fill="#333" />
      <line x1="61" y1="98" x2="59" y2="98" stroke="#333" strokeWidth="2" />
      <line x1="49" y1="98" x2="45" y2="97" stroke="#333" strokeWidth="1.5" />
      <line x1="71" y1="98" x2="75" y2="97" stroke="#333" strokeWidth="1.5" />
      
      {/* Relaxed smile */}
      <path d="M 54 104 Q 60 107 66 104" fill="none" stroke="#1e4d3d" strokeWidth="1.5" strokeLinecap="round" />
      
      {/* Drink with umbrella */}
      <g transform="translate(25, 110)">
        {/* Glass */}
        <path d="M 0 10 L 2 0 L 10 0 L 12 10 Z" fill="#60a5fa" opacity="0.6" />
        
        {/* Liquid */}
        <rect x="1" y="6" width="10" height="4" fill="#fb923c" opacity="0.7" />
        
        {/* Straw */}
        <rect x="6" y="-5" width="1" height="12" fill="#ef4444" />
        
        {/* Umbrella */}
        <path d="M 10 -5 Q 15 -3 15 0 Q 15 -3 20 -5" fill="#ef4444" />
        <line x1="15" y1="0" x2="15" y2="5" stroke="#8b4513" strokeWidth="0.5" />
      </g>
      
      {/* Legs relaxed */}
      <ellipse cx="70" cy="155" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="85" cy="158" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="115" cy="158" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="130" cy="155" rx="10" ry="7" fill="#7ca888" />
      <ellipse cx="145" cy="128" rx="8" ry="5" fill="#7ca888" />
      
      {/* ZZZ optional */}
      <text x="130" y="95" fontSize="10" fill="#86efac" opacity="0.5">z</text>
      <text x="138" y="88" fontSize="8" fill="#86efac" opacity="0.4">z</text>
    </svg>
  );
}
