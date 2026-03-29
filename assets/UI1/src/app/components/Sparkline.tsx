import React from 'react';
import {
  AreaChart,
  Area,
  ResponsiveContainer,
  Tooltip,
} from 'recharts';

const data = [
  { name: 'Mon', balance: 400 },
  { name: 'Tue', balance: 450 },
  { name: 'Wed', balance: 430 },
  { name: 'Thu', balance: 550 },
  { name: 'Fri', balance: 500 },
  { name: 'Sat', balance: 680 },
  { name: 'Sun', balance: 750 },
];

export function Sparkline() {
  return (
    <div className="h-[120px] w-full mt-4 -ml-4 min-w-0">
      <ResponsiveContainer width="99%" height={120}>
        <AreaChart data={data}>
          <defs>
            <linearGradient id="colorGlow" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#85efac" stopOpacity={0.6} />
              <stop offset="95%" stopColor="#85efac" stopOpacity={0} />
            </linearGradient>
            <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
              <feGaussianBlur stdDeviation="3" result="blur" />
              <feComposite in="SourceGraphic" in2="blur" operator="over" />
            </filter>
          </defs>
          <Tooltip
            contentStyle={{
              backgroundColor: 'rgba(6,44,33,0.9)',
              borderColor: '#85efac',
              borderRadius: '8px',
              color: '#fff',
              boxShadow: '0 0 10px rgba(133,239,172,0.3)',
            }}
            itemStyle={{ color: '#85efac' }}
          />
          <Area
            type="monotone"
            dataKey="balance"
            stroke="#85efac"
            strokeWidth={3}
            fillOpacity={1}
            fill="url(#colorGlow)"
            style={{ filter: 'url(#glow)' }}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
