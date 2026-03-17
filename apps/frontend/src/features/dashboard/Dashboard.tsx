import React from "react";
import { BarChart3, Users, Database, Server, Activity, ArrowUpRight, ArrowDownRight, Globe } from "lucide-react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
} from "recharts";

const GROWTH_DATA = [
  { name: "Week 1", users: 400 },
  { name: "Week 2", users: 600 },
  { name: "Week 3", users: 850 },
  { name: "Week 4", users: 1247 },
];

const VIEW_TYPES_DATA = [
  { name: "Table", value: 45 },
  { name: "Kanban", value: 25 },
  { name: "Chart", value: 20 },
  { name: "Calendar", value: 10 },
];

const INDUSTRIES_DATA = [
  { name: "Hospitality", value: 30 },
  { name: "Retail", value: 25 },
  { name: "Consulting", value: 20 },
  { name: "Others", value: 25 },
];

const KPI_ITEMS = [
  {
    label: "Active Users",
    value: "1,247",
    trend: "+14.2%",
    icon: Users,
    type: "positive",
  },
  {
    label: "Projects Created",
    value: "3,892",
    trend: "+8.4%",
    icon: Database,
    type: "positive",
  },
  {
    label: "Rows Processed",
    value: "12.4M",
    trend: "+22.1%",
    icon: Activity,
    type: "positive",
  },
  {
    label: "Adapter Uptime",
    value: "98.7%",
    trend: "-0.2%",
    icon: Server,
    type: "negative",
  },
];

const CHART_COLORS = ["#6366F1", "#8B5CF6", "#F59E0B", "#10B981"];
const THEME_COLORS = ["#6366F1", "#8B5CF6", "#F59E0B", "#10B981"];

export function AdminDashboard(): JSX.Element {
  return (
    <section className="dashboard">
      <header className="dashboard__header">
        <div>
          <h1 className="dashboard__title">
            <Globe className="dashboard__title-icon" />
            Platform Overview
          </h1>
          <p className="dashboard__subtitle">NovaSphere Operations Dashboard</p>
        </div>
        <div className="dashboard__actions">
          <button className="btn btn--ghost">Last 30 Days</button>
          <button className="btn btn--primary">Generate Report</button>
        </div>
      </header>

      <main className="dashboard__content">
        <div className="dashboard__kpis">
          {KPI_ITEMS.map((kpi) => {
            const Icon = kpi.icon;
            return (
              <article key={kpi.label} className="card">
                <div className="card__top">
                  <span className={`card__icon card__icon--${kpi.type}`}>
                    <Icon size={20} />
                  </span>
                  <span className={`card__trend card__trend--${kpi.type}`}>
                    {kpi.type === "negative" ? <ArrowDownRight size={14} /> : <ArrowUpRight size={14} />}
                    {kpi.trend}
                  </span>
                </div>
                <div className="card__body">
                  <h3 className="card__label">{kpi.label}</h3>
                  <p className="card__value">{kpi.value}</p>
                </div>
              </article>
            );
          })}
        </div>

        <div className="dashboard__charts dashboard__charts--top">
          <section className="panel panel--wide">
            <h3>User Signups (Last 30 Days)</h3>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={GROWTH_DATA}>
                <defs>
                  <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor={CHART_COLORS[0]} stopOpacity={0.28} />
                    <stop offset="95%" stopColor={CHART_COLORS[0]} stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} />
                <YAxis axisLine={false} tickLine={false} />
                <RechartsTooltip className="chart-tooltip" />
                <Area type="monotone" dataKey="users" stroke={CHART_COLORS[0]} strokeWidth={3} fill="url(#colorUsers)" />
              </AreaChart>
            </ResponsiveContainer>
          </section>

          <section className="panel">
            <h3>Most Popular View Types</h3>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={VIEW_TYPES_DATA} layout="vertical" margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#e2e8f0" />
                <XAxis type="number" hide />
                <YAxis dataKey="name" type="category" axisLine={false} tickLine={false} width={70} />
                <RechartsTooltip className="chart-tooltip" cursor={{ fill: "transparent" }} />
                <Bar dataKey="value" fill={CHART_COLORS[1]} radius={[0, 4, 4, 0]} barSize={20} />
              </BarChart>
            </ResponsiveContainer>
          </section>
        </div>

        <div className="dashboard__charts dashboard__charts--bottom">
          <section className="panel">
            <h3>Industries Served</h3>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={INDUSTRIES_DATA} cx="50%" cy="50%" innerRadius={60} outerRadius={90} paddingAngle={5} dataKey="value">
                  {INDUSTRIES_DATA.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={THEME_COLORS[index % THEME_COLORS.length]} />
                  ))}
                </Pie>
                <RechartsTooltip className="chart-tooltip" />
              </PieChart>
            </ResponsiveContainer>
            <div className="panel__centered">
              <span>100%</span>
              <small>Market</small>
            </div>
          </section>

          <section className="panel panel--feed">
            <div className="panel__title-bar">
              <h3>Recent Activity Feed</h3>
              <button className="btn btn--link">View All</button>
            </div>
            <div className="activity-list">
              {[
                { time: "2 mins ago", text: "New enterprise signup: Hotel Chain X", type: "success" },
                { time: "15 mins ago", text: "Adapter alert: Webhook delivery failed (retrying)", type: "warning" },
                { time: "1 hour ago", text: "System: Automated backup completed successfully", type: "info" },
                { time: "3 hours ago", text: 'User "DJ Surgeon" created new project "Restaurant Group"', type: "info" },
                { time: "5 hours ago", text: 'API rate limit warning for project "Marketing Agency"', type: "warning" },
                { time: "1 day ago", text: "Platform update v1.4.2 deployed", type: "success" },
              ].map((item, idx) => (
                <article key={idx} className="activity-item">
                  <span className={`activity-item__dot activity-item__dot--${item.type}`} />
                  <div>
                    <p>{item.text}</p>
                    <time>{item.time}</time>
                  </div>
                </article>
              ))}
            </div>
          </section>
        </div>
      </main>
    </section>
  );
}