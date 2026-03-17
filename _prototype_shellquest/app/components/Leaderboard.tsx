import { Trophy, Medal } from 'lucide-react';

export function Leaderboard() {
  const leaders = [
    { rank: 1, username: 'MoneyMaster99', points: 2450, isCurrentUser: false },
    { rank: 2, username: 'BudgetPro', points: 2280, isCurrentUser: false },
    { rank: 3, username: 'Username3189', points: 2150, isCurrentUser: true },
    { rank: 4, username: 'SaverSally', points: 2020, isCurrentUser: false },
    { rank: 5, username: 'InvestorMax', points: 1890, isCurrentUser: false },
  ];

  const getRankIcon = (rank: number) => {
    if (rank === 1) return <Trophy className="w-5 h-5 text-yellow-400" />;
    if (rank === 2) return <Medal className="w-5 h-5 text-gray-300" />;
    if (rank === 3) return <Medal className="w-5 h-5 text-orange-400" />;
    return null;
  };

  return (
    <div>
      <h2 className="text-sm text-gray-300 mb-3">Leaderboard</h2>
      <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-lg overflow-hidden">
        <table className="w-full">
          <thead className="bg-white/5 border-b border-white/20">
            <tr>
              <th className="text-left px-4 py-2 text-xs text-gray-300">#</th>
              <th className="text-left px-4 py-2 text-xs text-gray-300">User</th>
              <th className="text-right px-4 py-2 text-xs text-gray-300">Points</th>
            </tr>
          </thead>
          <tbody>
            {leaders.map((leader) => (
              <tr 
                key={leader.rank} 
                className={`border-b border-white/10 last:border-0 ${
                  leader.isCurrentUser ? 'bg-[#86efac]/20' : 'hover:bg-white/5'
                }`}
              >
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    {getRankIcon(leader.rank) || (
                      <span className="text-sm text-gray-300 w-5">{leader.rank}</span>
                    )}
                  </div>
                </td>
                <td className="px-4 py-3">
                  <span className={`text-sm ${leader.isCurrentUser ? 'text-[#86efac]' : 'text-gray-200'}`}>
                    {leader.username}
                    {leader.isCurrentUser && (
                      <span className="ml-2 text-xs text-[#86efac]">(You)</span>
                    )}
                  </span>
                </td>
                <td className="px-4 py-3 text-right">
                  <span className="text-sm text-gray-200">{leader.points.toLocaleString()}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}