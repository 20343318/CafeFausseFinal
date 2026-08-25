import { useCallback, useEffect, useRef, useState } from 'react'
import { useOperations } from '../../api/operations.js'
import { ErrorSummary, FormField, StatusPanel } from '../../components/FormPrimitives.jsx'
import { identityBody, validateIdentity } from '../../forms/validation.js'
import { useNewsletterLookup } from '../../forms/useNewsletterLookup.js'

const EMPTY_IDENTITY = { first_name: '', middle_initial: '', last_name: '', email: '', confirmation_email: '' }

function lookupCopy(lookup, dirty, result) {
  if (result && !result.error) return `Current preference: ${result.subscribed ? 'subscribed' : 'not subscribed'}.`
  if (lookup.state === 'waiting' || lookup.state === 'checking') return 'Checking your current newsletter preference…'
  if (lookup.state === 'matched') return dirty ? 'Your choice is retained and will be saved.' : `Current preference: ${lookup.subscribed ? 'subscribed' : 'not subscribed'}.`
  if (lookup.state === 'not_found') return 'No existing newsletter preference was found.'
  if (lookup.state === 'conflict') return 'The entered identity details do not match our records.'
  if (lookup.state === 'indeterminate') return 'We could not check your newsletter status. You can still save the final choice shown.'
  if (lookup.state === 'read_failure') return 'Newsletter status is temporarily unavailable. You can retry the status check or save the final choice shown.'
  if (lookup.state === 'error') return 'Newsletter status could not be checked because the service response was invalid. No status retry is available.'
  return 'Status not checked. Complete the identity fields to check it.'
}

export function NewsletterPreferences() {
  const operations = useOperations()
  const [values, setValues] = useState(EMPTY_IDENTITY)
  const [touched, setTouched] = useState({})
  const [errors, setErrors] = useState({})
  const [subscribed, setSubscribed] = useState(false)
  const [choiceVersion, setChoiceVersion] = useState(0)
  const [lookupRetryVersion, setLookupRetryVersion] = useState(0)
  const [pending, setPending] = useState(false)
  const [result, setResult] = useState(null)
  const [recovery, setRecovery] = useState(null)
  const [summaryFocusVersion, setSummaryFocusVersion] = useState(0)
  const summaryRef = useRef(null)
  const onUntouchedResult = useCallback((response) => {
    if (response.status === 'matched') setSubscribed(response.subscribed)
    if (response.status === 'not_found') setSubscribed(false)
  }, [])
  const lookup = useNewsletterLookup({ values, query: operations.queryNewsletterStatus, choiceVersion, onUntouchedResult, retryVersion: lookupRetryVersion })
  const locked = pending || Boolean(recovery)

  useEffect(() => {
    if (summaryFocusVersion) summaryRef.current?.focus()
  }, [summaryFocusVersion])

  function update(field, value) {
    setValues((current) => ({ ...current, [field]: value }))
    setResult(null)
    if (touched[field]) setErrors(validateIdentity({ ...values, [field]: value }))
  }

  function blur(field) {
    setTouched((current) => ({ ...current, [field]: true }))
    setErrors(validateIdentity(values))
  }

  async function sendPreference(body) {
    if (pending) return
    setPending(true)
    setResult(null)
    try {
      const response = await operations.setNewsletterPreference(body)
      setSubscribed(response.subscribed)
      setChoiceVersion(0)
      setRecovery(null)
      setResult(response)
    } catch (cause) {
      setRecovery(null)
      const error = cause.response?.error
      if (error?.code === 'validation_failed') {
        setErrors(Object.fromEntries(error.fields.map((field) => [field.field, field.message])))
        setSummaryFocusVersion((version) => version + 1)
      } else if (error?.code === 'customer_identity_conflict') {
        setErrors({ first_name: 'The entered identity details do not match our records.' })
        setSummaryFocusVersion((version) => version + 1)
      } else if (error?.code === 'middle_initial_conflict') {
        setErrors({ middle_initial: 'The middle initial conflicts with the existing identity details.' })
        setSummaryFocusVersion((version) => version + 1)
      } else {
        const unknown = error?.outcome_unknown || !error
        const retryable = unknown || error?.retryable
        setRecovery(retryable ? { body, unknown } : null)
        setResult({ error: true, unknown, code: error?.code || 'transport_failure' })
      }
    } finally {
      setPending(false)
    }
  }

  function submit(event) {
    event.preventDefault()
    const nextErrors = validateIdentity(values)
    setTouched({ first_name: true, middle_initial: true, last_name: true, email: true, confirmation_email: true })
    setErrors(nextErrors)
    if (Object.keys(nextErrors).length) {
      queueMicrotask(() => summaryRef.current?.focus())
      return
    }
    const body = Object.freeze({ ...identityBody(values), subscribed })
    sendPreference(body)
  }

  const fields = [
    ['first_name', 'First name', 'given-name', false], ['middle_initial', 'Middle initial', 'additional-name', true], ['last_name', 'Last name', 'family-name', false], ['email', 'Email', 'email', false], ['confirmation_email', 'Confirm email', 'off', false],
  ]

  return (
    <form className="newsletter-form form-card" aria-label="Newsletter preferences" onSubmit={submit} aria-busy={pending}>
      <ErrorSummary errors={errors} summaryRef={summaryRef} idPrefix="newsletter_" />
      <fieldset disabled={locked}>
        <legend>Your details</legend>
        <div className="form-grid">
          {fields.map(([id, label, autoComplete, optional]) => (
            <FormField key={id} id={`newsletter_${id}`} label={label} optional={optional} error={errors[id]}>
              {({ describedBy }) => <input id={`newsletter_${id}`} name={id} type={id.includes('email') ? 'email' : 'text'} autoComplete={autoComplete} value={values[id]} onChange={(event) => update(id, event.target.value)} onBlur={() => blur(id)} aria-invalid={Boolean(errors[id])} aria-describedby={describedBy} required={!optional} maxLength={id.includes('email') ? 254 : undefined} />}
            </FormField>
          ))}
        </div>
      </fieldset>
      <fieldset disabled={locked}>
        <legend>Newsletter preference</legend>
        <label className="checkbox-row" htmlFor="newsletter_subscribed">
          <input id="newsletter_subscribed" type="checkbox" checked={subscribed} onChange={(event) => { setSubscribed(event.target.checked); setChoiceVersion((version) => version + 1); setResult(null) }} />
          <span>Subscribe me to the Café Fausse newsletter</span>
        </label>
        <p id="newsletter-lookup-status" role="status">{lookupCopy(lookup, choiceVersion > 0, result)}</p>
        {(lookup.state === 'indeterminate' || lookup.state === 'read_failure') && lookup.retryable && <button className="button button--secondary" type="button" onClick={() => setLookupRetryVersion((version) => version + 1)}>Retry newsletter status</button>}
        <p className="field-help">Clearing the checkbox saves an unsubscribe preference. Unsubscribing does not delete a customer.</p>
      </fieldset>
      {result && !result.error && <StatusPanel tone="success" title="Newsletter preference saved"><p>{result.result === 'no_customer_no_change' ? 'You are not subscribed; no new customer was created.' : `Authoritative preference: ${result.subscribed ? 'subscribed' : 'not subscribed'}.`}</p></StatusPanel>}
      {result?.error && <StatusPanel tone={result.unknown ? 'warning' : 'error'} title={result.unknown ? 'Newsletter result not confirmed' : 'Newsletter preference not saved'} role="alert"><p>{result.unknown ? 'The preference may already have been saved. Resend the exact same preference to resolve it.' : 'We could not save your newsletter preference right now. Your choice is preserved.'}</p></StatusPanel>}
      <div className="action-group">
        {recovery ? <button className="button button--primary" type="button" onClick={() => sendPreference(recovery.body)} disabled={pending}>{pending ? 'Resending preference…' : 'Resend the same preference'}</button> : <button className="button button--primary" type="submit" disabled={pending}>{pending ? 'Saving preference…' : 'Save newsletter preference'}</button>}
        {recovery && <button className="button button--secondary" type="button" onClick={() => { setRecovery(null); setResult(null) }}>Leave unresolved</button>}
      </div>
      {pending && <p role="status">Saving your newsletter preference…</p>}
    </form>
  )
}
