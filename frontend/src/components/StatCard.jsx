export default function StatCard({ label, value, icon, tone = 'default', hint }) {
  return (
    <div className={`stat stat-${tone}`}>
      <div className="stat-icon">{icon}</div>
      <div>
        <small>{label}</small>
        <strong>{value}</strong>
        {hint && <span>{hint}</span>}
      </div>
    </div>
  )
}
