import { useState } from 'react'

const empty = { sku: '', name: '', category: 'General', description: '', quantity: 0, reorder_level: 10, unit_price: 0 }

export default function ProductModal({ product, onClose, onSave }) {
  const [form, setForm] = useState(product ? { ...product } : empty)
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)
  const editing = Boolean(product)

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value })

  const submit = async (e) => {
    e.preventDefault()
    setSaving(true)
    setError('')
    try {
      const payload = {
        name: form.name,
        category: form.category || 'General',
        description: form.description || '',
        quantity: Number(form.quantity),
        reorder_level: Number(form.reorder_level),
        unit_price: Number(form.unit_price),
      }
      if (!editing) payload.sku = form.sku.trim().toUpperCase()
      await onSave(payload)
      onClose()
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <form className="modal" onSubmit={submit} onClick={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <div>
            <p className="eyebrow">{editing ? 'EDIT PRODUCT' : 'NEW PRODUCT'}</p>
            <h2>{editing ? form.name : 'Add a product'}</h2>
          </div>
          <button type="button" className="close" onClick={onClose} aria-label="Close">×</button>
        </div>
        {error && <div className="alert">⚠ {error}</div>}
        <div className="form-row">
          <label>SKU
            <input value={form.sku} onChange={set('sku')} required disabled={editing} placeholder="e.g. LAP-001" />
          </label>
          <label>Category
            <input value={form.category} onChange={set('category')} placeholder="Laptops" />
          </label>
        </div>
        <label>Product name
          <input value={form.name} onChange={set('name')} required placeholder="e.g. Dell Latitude 5540" />
        </label>
        <label>Description
          <textarea value={form.description} onChange={set('description')} rows={2} placeholder="Optional details" />
        </label>
        <div className="form-row three">
          <label>Quantity
            <input type="number" min="0" value={form.quantity} onChange={set('quantity')} required />
          </label>
          <label>Reorder level
            <input type="number" min="0" value={form.reorder_level} onChange={set('reorder_level')} required />
          </label>
          <label>Unit price (₹)
            <input type="number" min="0" step="0.01" value={form.unit_price} onChange={set('unit_price')} required />
          </label>
        </div>
        <button className="primary full" disabled={saving}>{saving ? 'Saving…' : editing ? 'Save changes' : 'Create product'}</button>
      </form>
    </div>
  )
}
