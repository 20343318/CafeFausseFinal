import { fieldLabels, sortErrors } from '../forms/validation.js'

export function StatusPanel({ tone = 'information', title, children, role = 'status', actions }) {
  return (
    <section className={`status-panel status-panel--${tone}`} role={role}>
      <h3>{title}</h3>
      {children}
      {actions && <div className="action-group">{actions}</div>}
    </section>
  )
}

export function ErrorSummary({ errors, summaryRef, idPrefix = '' }) {
  const entries = sortErrors(errors)
  if (!entries.length) return null
  return (
    <section className="error-summary" role="alert" tabIndex="-1" ref={summaryRef} aria-labelledby="error-summary-title">
      <h3 id="error-summary-title">Please review the fields below.</h3>
      <ul>
        {entries.map(([field, message]) => (
          <li key={field}><a href={`#${idPrefix}${field}`}>{fieldLabels[field] || field}: {message}</a></li>
        ))}
      </ul>
    </section>
  )
}

export function FormField({ id, label, optional = false, helper, error, children }) {
  const describedBy = [helper ? `${id}-help` : '', error ? `${id}-error` : ''].filter(Boolean).join(' ') || undefined
  return (
    <div className="form-field">
      <label htmlFor={id}>{label} <span className="field-requirement">{optional ? 'Optional' : 'Required'}</span></label>
      {helper && <p id={`${id}-help`} className="field-help">{helper}</p>}
      {typeof children === 'function' ? children({ describedBy }) : children}
      {error && <p id={`${id}-error`} className="field-error">{error}</p>}
    </div>
  )
}
