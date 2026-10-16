import { useCallback, useEffect, useState } from 'react'
import { api } from './api.js'
import StatCard from './components/StatCard.jsx'
import ProductModal from './components/ProductModal.jsx'
import MovementModal from './components/MovementModal.jsx'

const money = (n) => `₹${Number(n).toLocaleString('en-IN', { maximumFractionDigits: 2 })}`
const timeAgo = (iso) => {
  const diff = (Date.now() - new Date(iso).getTime()) / 1000
  if (diff < 60) return 'just now'
  if (diff < 3600) return `${Math.floor(diff / 60)} min ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)} hr ago`
  return `${Math.floor(diff / 86400)} d ago`
}

export default function App() {
  const [products, setProducts] = useState([])
  const [stats, setStats] = useState(null)
  const [movements, setMovements] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [filter, setFilter] = useState('ALL')
  const [search, setSearch] = useState('')
  const [modal, setModal] = useState(null) // {type:'product', product?} | {type:'movement', product}
  const [menuOpen, setMenuOpen] = useState(false)

  const load = useCallback(async () => {
    try {
      setError('')
      const [p, s, m] = await Promise.all([api.listProducts({ search }), api.stats(), api.movements()])
      setProducts(p)
      setStats(s)
      setMovements(m)
    } catch (e) {
      setError(`${e.message}. Is the backend and PostgreSQL running?`)
    } finally {
      setLoading(false)
    }
  }, [search])

  useEffect(() => { load() }, [load])

  const visible = products.filter((p) => {
    if (filter === 'LOW') return p.low_stock && p.quantity > 0
    if (filter === 'OUT') return p.quantity === 0
    if (filter === 'OK') return !p.low_stock
    return true
  })
  const categories = [...new Set(products.map((p) => p.category))].sort()

  const remove = async (p) => {
    if (!window.confirm(`Delete ${p.name}?`)) return
    await api.deleteProduct(p.id)
    load()
  }

  return (
    <div className="app">
      <aside className={`sidebar ${menuOpen ? 'open' : ''}`}>
        <div className="brand">
          <span className="brand-mark">S</span>
          <div><b>StockPilot</b><small>Inventory control</small></div>
        </div>
        <nav>
          <a className="active">▦ <span>Dashboard</span></a>
          <a>▤ <span>Products</span></a>
          <a>⇅ <span>Movements</span></a>
          <a>◔ <span>Reports</span></a>
        </nav>
        <div className="side-bottom">
          <div className="upgrade">
            <strong>DevSecOps Capstone</strong>
            <p>FastAPI · React · PostgreSQL · Kubernetes</p>
          </div>
          <div className="pipeline"><span>CI</span><i /><span>Scan</span><i /><span>GHCR</span><i /><span>ArgoCD</span></div>
        </div>
      </aside>

      <main className="main">
        <header>
          <div className="header-left">
            <button className="icon-btn menu" onClick={() => setMenuOpen(!menuOpen)} aria-label="Menu">☰</button>
            <div>
              <p className="eyebrow">WAREHOUSE / OVERVIEW</p>
              <h1>Inventory dashboard</h1>
              <p className="muted">Track stock levels, reorder alerts and movements in real time. Demo build.</p>
            </div>
          </div>
          <button className="primary" onClick={() => setModal({ type: 'product' })}>＋ New product</button>
        </header>

        {error && <div className="alert">⚠ {error}</div>}

        <section className="stats">
          <StatCard label="Products" value={stats?.total_products ?? '—'} icon="▤" hint={`${stats?.categories ?? 0} categories`} />
          <StatCard label="Units in stock" value={stats?.total_units ?? '—'} icon="◫" />
          <StatCard label="Inventory value" value={stats ? money(stats.inventory_value) : '—'} icon="₹" tone="green" />
          <StatCard label="Low stock" value={stats?.low_stock_count ?? '—'} icon="⚠" tone="amber" hint={`${stats?.out_of_stock_count ?? 0} out of stock`} />
        </section>

        <section className="content-grid">
          <div className="panel products-panel">
            <div className="panel-head">
              <div>
                <h2>Products</h2>
                <p className="muted">{visible.length} of {products.length} shown</p>
              </div>
              <div className="toolbar">
                <input className="search" placeholder="Search name or SKU…" value={search} onChange={(e) => setSearch(e.target.value)} />
                <div className="filters">
                  {[['ALL', 'All'], ['OK', 'Healthy'], ['LOW', 'Low'], ['OUT', 'Out']].map(([k, label]) => (
                    <button key={k} className={filter === k ? 'selected' : ''} onClick={() => setFilter(k)}>{label}</button>
                  ))}
                </div>
              </div>
            </div>

            {loading ? (
              <div className="empty">Loading inventory…</div>
            ) : (
              <div className="table-wrap">
                <table>
                  <thead>
                    <tr><th>Product</th><th>Category</th><th>Stock</th><th>Unit price</th><th>Status</th><th></th></tr>
                  </thead>
                  <tbody>
                    {visible.map((p) => {
                      const status = p.quantity === 0 ? 'out' : p.low_stock ? 'low' : 'ok'
                      return (
                        <tr key={p.id}>
                          <td>
                            <div className="product-cell">
                              <span className={`dot ${status}`} />
                              <div><b>{p.name}</b><small>{p.sku}{p.description ? ` · ${p.description}` : ''}</small></div>
                            </div>
                          </td>
                          <td><span className="chip">{p.category}</span></td>
                          <td><b>{p.quantity}</b> <small className="muted">/ reorder at {p.reorder_level}</small></td>
                          <td>{money(p.unit_price)}</td>
                          <td><span className={`status ${status}`}>{status === 'ok' ? 'In stock' : status === 'low' ? 'Low stock' : 'Out of stock'}</span></td>
                          <td className="actions">
                            <button className="icon-btn" title="Adjust stock" onClick={() => setModal({ type: 'movement', product: p })}>⇅</button>
                            <button className="icon-btn" title="Edit" onClick={() => setModal({ type: 'product', product: p })}>✎</button>
                            <button className="icon-btn danger" title="Delete" onClick={() => remove(p)}>🗑</button>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
                {!visible.length && <div className="empty">No products match this filter. Create one to get started.</div>}
              </div>
            )}
            {categories.length > 0 && (
              <div className="category-row">{categories.map((c) => <span key={c} className="chip ghost">{c}</span>)}</div>
            )}
          </div>

          <aside className="panel activity">
            <div className="panel-head">
              <div><h2>Recent movements</h2><p className="muted">Latest stock in / out events.</p></div>
            </div>
            {movements.length === 0 && <div className="empty small">No movements yet.</div>}
            {movements.map((m) => (
              <div className="activity-row" key={m.id}>
                <span className={`activity-icon ${m.movement_type.toLowerCase()}`}>{m.movement_type === 'IN' ? '⬆' : '⬇'}</span>
                <div>
                  <b>{m.movement_type === 'IN' ? '+' : '−'}{m.quantity} · {m.product_name}</b>
                  <small>{m.note || m.product_sku} · {timeAgo(m.created_at)}</small>
                </div>
              </div>
            ))}
          </aside>
        </section>
      </main>

      {modal?.type === 'product' && (
        <ProductModal
          product={modal.product}
          onClose={() => setModal(null)}
          onSave={async (data) => { modal.product ? await api.updateProduct(modal.product.id, data) : await api.createProduct(data); load() }}
        />
      )}
      {modal?.type === 'movement' && (
        <MovementModal
          product={modal.product}
          onClose={() => setModal(null)}
          onSave={async (data) => { await api.recordMovement(modal.product.id, data); load() }}
        />
      )}
    </div>
  )
}
