export function ProgressBar() {
  const goals = [
    { label: 'Current Weekly Goals', value: 65, color: 'bg-[#86efac]' },
    { label: 'Overall Completion', value: 42, color: 'bg-[#4ade80]' },
  ];

  return (
    <div>
      <h2 className="text-sm text-gray-300 mb-3">Progress Bar</h2>
      <div className="space-y-4">
        {goals.map((goal) => (
          <div key={goal.label}>
            <div className="flex justify-between text-sm mb-2">
              <span className="text-gray-200">{goal.label}</span>
              <span className="text-gray-300">{goal.value}%</span>
            </div>
            <div className="w-full bg-white/20 rounded-full h-3">
              <div 
                className={`${goal.color} h-3 rounded-full transition-all`}
                style={{ width: `${goal.value}%` }}
              />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}