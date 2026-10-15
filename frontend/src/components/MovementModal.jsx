import { useState } from 'react'

export default function MovementModal({ product, onClose, onSave }) {
  const [type, setType] = useState('IN')
  const [quantity, setQuantity] = useState(1)
  const [note, setNote] = useState('')
  const [error, setError] = useState('')

  const submit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await onSave({ movement_type: type, quantity: Number(quantity), note })
      onClose()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <form className="modal" onSubmit={submit} onClick={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <div>
            <p className="eyebrow">ADJUST STOCK</p>
            <h2>{product.name}</h2>
            <p className="muted">Current stock: <b>{product.quantity}</b> units</p>
          </div>
          <button type="button" className="close" onClick={onClose} aria-label="Close">×</button>
        </div>
        {error && <div className="alert">⚠ {error}</div>}
        <div className="segmented">
          <button type="button" className={type === 'IN' ? 'selected in' : ''} onClick={() => setType('IN')}>⬆ Stock in</button>
          <button type="button" className={type === 'OUT' ? 'selected out' : ''} onClick={() => setType('OUT')}>⬇ Stock out</button>
        </div>
        <label>Quantity
          <input type="number" min="1" value={quantity} onChange={(e) => setQuantity(e.target.value)} required />
        </label>
        <label>Note
          <input value={note} onChange={(e) => setNote(e.target.value)} placeholder={type === 'IN' ? 'Supplier delivery' : 'Customer order #1024'} />
        </label>
        <button className="primary full">Record movement</button>
      </form>
    </div>
  )
}
