import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { Link } from 'react-router'
import { useOperations } from '../../api/operations.js'
import { ErrorSummary, FormField, StatusPanel } from '../../components/FormPrimitives.jsx'
import { identityBody, validateIdentity } from '../../forms/validation.js'
import { useNewsletterLookup } from '../../forms/useNewsletterLookup.js'
import { formatClockTime, formatRestaurantDateTime } from '../../utils/time-formatting.js'

const EMPTY_CUSTOMER = { first_name: '', middle_initial: '', last_name: '', email: '', confirmation_email: '', phone: '' }
const DAY_NAMES = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

function dateLabel(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return value
  const [year, month, day] = value.split('-')
  return `${month}/${day}/${year}`
}

function contextFailure(cause) {
  const error = cause?.response?.error
  return error?.code || 'transport_failure'
}

export function ReservationContextBoundary({ children }) {
  const operations = useOperations()
  const [state, setState] = useState({ status: 'loading' })
  const sequence = useRef(0)

  const load = useCallback(async () => {
    const request = ++sequence.current
    setState({ status: 'loading' })
    try {
      const data = await operations.getReservationContext()
      if (request === sequence.current) setState({ status: 'ready', data })
    } catch (cause) {
      if (request === sequence.current) setState({ status: 'error', code: contextFailure(cause) })
    }
  }, [operations])

  useEffect(() => { load() }, [load])

  if (state.status === 'loading') {
    return <section className="context-skeleton" aria-busy="true"><p role="status">Loading reservation options…</p><span aria-hidden="true" /><span aria-hidden="true" /></section>
  }
  if (state.status === 'error') {
    return <StatusPanel tone="error" title="Reservation options are unavailable" role="alert" actions={<button className="button button--secondary" type="button" onClick={load}>Try again</button>}><p>We could not load current booking options. No hours or limits have been assumed.</p></StatusPanel>
  }
  return children(state.data)
}

export function ReservationFeatureBoundary() {
  return <ReservationContextBoundary>{(context) => <ReservationWorkflow context={context} />}</ReservationContextBoundary>
}

function ReservationWorkflow({ context }) {
  const operations = useOperations()
  const [localDate, setLocalDate] = useState('')
  const [partySize, setPartySize] = useState('')
  const [choiceErrors, setChoiceErrors] = useState({})
  const [availability, setAvailability] = useState({ status: 'idle' })
  const [selectedStart, setSelectedStart] = useState('')
  const [slotNotice, setSlotNotice] = useState('')
  const [customer, setCustomer] = useState(EMPTY_CUSTOMER)
  const [touched, setTouched] = useState({})
  const [errors, setErrors] = useState({})
  const [newsletterChecked, setNewsletterChecked] = useState(false)
  const [newsletterChoiceVersion, setNewsletterChoiceVersion] = useState(0)
  const [lookupRetryVersion, setLookupRetryVersion] = useState(0)
  const [pending, setPending] = useState(false)
  const [feedback, setFeedback] = useState(null)
  const [recovery, setRecovery] = useState(null)
  const [confirmation, setConfirmation] = useState(null)
  const availabilitySequence = useRef(0)
  const currentKey = useRef('')
  const availabilityMessageRef = useRef(null)
  const summaryRef = useRef(null)
  const confirmationRef = useRef(null)
  const onUntouchedLookup = useCallback((result) => {
    if (result.status === 'matched') setNewsletterChecked(result.subscribed)
    if (result.status === 'not_found') setNewsletterChecked(false)
  }, [])
  const lookup = useNewsletterLookup({ values: customer, query: operations.queryNewsletterStatus, choiceVersion: newsletterChoiceVersion, onUntouchedResult: onUntouchedLookup, retryVersion: lookupRetryVersion })
  const locked = pending || Boolean(recovery)
  const key = localDate && partySize ? `${localDate}|${partySize}` : ''
  currentKey.current = key
  const selectedSlot = availability.status === 'ready' ? availability.data.slots.find((slot) => slot.starts_at_local === selectedStart && slot.available) : undefined

  useEffect(() => {
    if (slotNotice) availabilityMessageRef.current?.focus()
  }, [slotNotice])

  useEffect(() => {
    if (confirmation) confirmationRef.current?.focus()
  }, [confirmation])

  function validateChoices(date = localDate, party = partySize) {
    const next = {}
    if (!date) next.local_date = 'Choose a reservation date.'
    else if (date < context.reservable_date_range.minimum_local_date || date > context.reservable_date_range.maximum_local_date) next.local_date = 'Choose a date inside the current reservable range.'
    const numericParty = Number(party)
    if (!party) next.party_size = 'Enter a party size.'
    else if (!Number.isInteger(numericParty) || numericParty < 1 || numericParty > context.maximum_party_size) next.party_size = `Enter a whole number from 1 to ${context.maximum_party_size}.`
    return next
  }

  function invalidateAvailability() {
    availabilitySequence.current += 1
    setAvailability({ status: 'idle', wasRequested: availability.status !== 'idle' || availability.wasRequested })
    setSelectedStart('')
    setSlotNotice('')
  }

  function changeDate(value) {
    setLocalDate(value)
    setChoiceErrors(validateChoices(value, partySize))
    invalidateAvailability()
  }

  function changeParty(value) {
    setPartySize(value)
    setChoiceErrors(validateChoices(localDate, value))
    invalidateAvailability()
  }

  async function checkAvailability() {
    const nextErrors = validateChoices()
    setChoiceErrors(nextErrors)
    if (Object.keys(nextErrors).length || availability.status === 'loading') return
    const requestKey = key
    const request = ++availabilitySequence.current
    const priorSelection = selectedStart
    setSelectedStart('')
    setSlotNotice('')
    setAvailability({ status: 'loading', key: requestKey, wasRequested: true })
    try {
      const data = await operations.getReservationAvailability({ local_date: localDate, party_size: Number(partySize) })
      if (request !== availabilitySequence.current || requestKey !== currentKey.current) return
      setAvailability({ status: 'ready', key: requestKey, data, wasRequested: true })
      if (priorSelection && !data.slots.some((slot) => slot.starts_at_local === priorSelection && slot.available)) {
        setSlotNotice('Your selected time is no longer available. Please choose another.')
        queueMicrotask(() => availabilityMessageRef.current?.focus())
      }
    } catch (cause) {
      if (request !== availabilitySequence.current || requestKey !== currentKey.current) return
      const error = cause.response?.error
      setAvailability({ status: 'error', key: requestKey, code: error?.code || 'transport_failure', retryable: !error || error.retryable === true, transport: !error, wasRequested: true })
    }
  }

  function updateCustomer(field, value) {
    const next = { ...customer, [field]: value }
    setCustomer(next)
    setFeedback(null)
    if (touched[field]) setErrors(validateIdentity(next, { includePhone: true }))
  }

  function blurCustomer(field) {
    setTouched((current) => ({ ...current, [field]: true }))
    setErrors(validateIdentity(customer, { includePhone: true }))
  }

  const newsletterAction = !['matched', 'not_found'].includes(lookup.state) || newsletterChoiceVersion === 0
    ? 'no_change'
    : newsletterChecked ? 'subscribe' : 'unsubscribe'

  const identityErrors = validateIdentity(customer, { includePhone: true })
  const eligibilityReason = useMemo(() => {
    if (Object.keys(validateChoices()).length) return 'Choose a valid date and party size.'
    if (!selectedSlot) return 'Choose an available time.'
    if (Object.keys(identityErrors).length) return 'Complete the required customer details.'
    if (lookup.state === 'conflict') return 'Correct the identity conflict.'
    return ''
  }, [localDate, partySize, selectedSlot, customer, lookup.state])
  const eligible = !eligibilityReason && !locked

  function reservationBody() {
    return Object.freeze({
      ...identityBody(customer),
      ...(customer.phone.trim() ? { phone: customer.phone.trim() } : {}),
      starts_at_local: selectedSlot.starts_at_local,
      utc_offset_minutes: selectedSlot.utc_offset_minutes,
      party_size: Number(partySize),
      newsletter_action: newsletterAction,
    })
  }

  function mapServerFields(fields = []) {
    const next = {}
    let invalidateSchedule = false
    const invalidStartCodes = new Set(['nonexistent_local_time', 'ambiguous_local_time', 'utc_offset_mismatch', 'date_outside_booking_window', 'insufficient_same_day_lead', 'invalid_reservation_time'])
    for (const field of fields) {
      if ((field.field === 'starts_at_local' && invalidStartCodes.has(field.code))
        || (field.field === 'utc_offset_minutes' && field.code === 'utc_offset_mismatch')) {
        invalidateSchedule = true
      } else if ((field.field === 'local_date' && ['out_of_range', 'invalid_date'].includes(field.code))
        || (field.field === 'party_size' && ['out_of_range', 'invalid_integer'].includes(field.code))) {
        setChoiceErrors((current) => ({ ...current, [field.field]: field.message }))
        invalidateSchedule = true
      } else next[field.field] = field.message
    }
    if (invalidateSchedule) {
      availabilitySequence.current += 1
      setAvailability({ status: 'idle', wasRequested: true })
      setSelectedStart('')
      setSlotNotice('The submitted schedule is no longer current. Check availability again before choosing a time.')
      queueMicrotask(() => availabilityMessageRef.current?.focus())
    }
    if (Object.keys(next).length) setErrors(next)
    if (!invalidateSchedule || Object.keys(next).length) queueMicrotask(() => summaryRef.current?.focus())
  }

  async function sendReservation(body) {
    if (pending) return
    setPending(true)
    setFeedback(null)
    try {
      const response = await operations.createReservation(body)
      setRecovery(null)
      setConfirmation(response)
      setCustomer(EMPTY_CUSTOMER)
      setLocalDate('')
      setPartySize('')
      setAvailability({ status: 'idle' })
      setSelectedStart('')
      setNewsletterChecked(false)
      setNewsletterChoiceVersion(0)
      queueMicrotask(() => confirmationRef.current?.focus())
    } catch (cause) {
      setRecovery(null)
      const error = cause.response?.error
      const code = error?.code
      if (code === 'validation_failed') {
        mapServerFields(error.fields)
        setFeedback({ tone: 'error', title: 'Please correct the reservation details', text: 'The submitted fields need attention.' })
      } else if (code === 'customer_identity_conflict') {
        setErrors({ first_name: 'The entered identity details do not match our records.' })
        setFeedback({ tone: 'error', title: 'Identity details do not match', text: 'Review your name and email.' })
        queueMicrotask(() => summaryRef.current?.focus())
      } else if (code === 'middle_initial_conflict') {
        setErrors({ middle_initial: 'The middle initial conflicts with the existing identity details.' })
        setFeedback({ tone: 'error', title: 'Middle initial needs attention', text: 'Correct or omit the middle initial where valid.' })
        queueMicrotask(() => summaryRef.current?.focus())
      } else if (code === 'reservation_overlap') {
        setSelectedStart('')
        setSlotNotice('This customer already has an overlapping reservation. Choose another time.')
        setFeedback({ tone: 'error', title: 'Choose another time', text: 'The existing reservation is not shown here.' })
        queueMicrotask(() => availabilityMessageRef.current?.focus())
      } else if (code === 'reservation_unavailable') {
        setSelectedStart('')
        setAvailability({ status: 'idle', wasRequested: true })
        setSlotNotice('That time is no longer available. Refresh the current schedule and choose another.')
        setFeedback({ tone: 'error', title: 'Reservation time unavailable', text: 'Your customer details are preserved.' })
        queueMicrotask(() => availabilityMessageRef.current?.focus())
      } else {
        const unknown = error?.outcome_unknown || !error
        const confirmationUnavailable = code === 'reservation_confirmation_unavailable'
        const retryable = unknown || confirmationUnavailable || error?.retryable === true
        if (retryable) setRecovery({ body, unknown, confirmationUnavailable })
        setFeedback({
          tone: unknown || confirmationUnavailable ? 'warning' : 'error',
          title: unknown ? 'Reservation result not confirmed' : confirmationUnavailable ? 'Reservation exists; confirmation unavailable' : 'Reservation could not be processed',
          text: unknown ? 'The request may already have been saved. Retry the exact same reservation to resolve it safely.' : confirmationUnavailable ? 'The reservation is known to exist. Retry the same details to reconstruct its confirmation.' : retryable ? 'Your exact details are preserved. Use the retry action when you are ready.' : 'Your details are preserved. No identical retry action is available for this known response.',
        })
      }
    } finally {
      setPending(false)
    }
  }

  function submit(event) {
    event.preventDefault()
    const nextErrors = validateIdentity(customer, { includePhone: true })
    const nextChoiceErrors = validateChoices()
    setTouched({ first_name: true, middle_initial: true, last_name: true, email: true, confirmation_email: true, phone: true })
    setErrors(nextErrors)
    setChoiceErrors(nextChoiceErrors)
    if (Object.keys(nextErrors).length || Object.keys(nextChoiceErrors).length || !selectedSlot) {
      if (!selectedSlot) setSlotNotice('Choose an available time before reserving.')
      queueMicrotask(() => summaryRef.current?.focus())
      return
    }
    sendReservation(reservationBody())
  }

  if (confirmation) return <ReservationConfirmationView result={confirmation} restaurantTimezone={context.restaurant_timezone} headingRef={confirmationRef} onNew={() => setConfirmation(null)} />

  return (
    <form className="reservation-form" aria-label="Reservation" onSubmit={submit} aria-busy={pending} noValidate>
      <p className="ready-status" role="status">Reservation options are ready.</p>
      <ContextSummary context={context} />
      <ErrorSummary errors={{ ...choiceErrors, ...errors }} summaryRef={summaryRef} />
      <fieldset className="form-card" disabled={locked}>
        <legend>1. Choose a date and party size</legend>
        <div className="choice-grid">
          <FormField id="local_date" label="Reservation date" helper={`Restaurant-local date. Choose from ${dateLabel(context.reservable_date_range.minimum_local_date)} through ${dateLabel(context.reservable_date_range.maximum_local_date)}, inclusive.`} error={choiceErrors.local_date}>
            {({ describedBy }) => <input id="local_date" type="date" value={localDate} min={context.reservable_date_range.minimum_local_date} max={context.reservable_date_range.maximum_local_date} onChange={(event) => changeDate(event.target.value)} aria-invalid={Boolean(choiceErrors.local_date)} aria-describedby={describedBy} required />}
          </FormField>
          <FormField id="party_size" label="Party size" helper={`Enter a whole number from 1 to ${context.maximum_party_size}.`} error={choiceErrors.party_size}>
            {({ describedBy }) => <input id="party_size" type="number" inputMode="numeric" min="1" max={context.maximum_party_size} step="1" value={partySize} onChange={(event) => changeParty(event.target.value)} aria-invalid={Boolean(choiceErrors.party_size)} aria-describedby={describedBy} required />}
          </FormField>
        </div>
        <button className="button button--secondary" type="button" onClick={checkAvailability} disabled={availability.status === 'loading' || Object.keys(validateChoices()).length > 0}>{availability.wasRequested ? 'Update times' : 'Check availability'}</button>
      </fieldset>
      <AvailabilityArea availability={availability} selectedStart={selectedStart} setSelectedStart={(value) => { setSelectedStart(value); setSlotNotice('') }} slotNotice={slotNotice} messageRef={availabilityMessageRef} onRetry={checkAvailability} locked={locked} />
      <CustomerAndReservationFormArea customer={customer} update={updateCustomer} blur={blurCustomer} errors={errors} locked={locked} lookup={lookup} checked={newsletterChecked} choiceDirty={newsletterChoiceVersion > 0} onRetryLookup={() => setLookupRetryVersion((version) => version + 1)} onChecked={(checked) => { setNewsletterChecked(checked); setNewsletterChoiceVersion((version) => version + 1) }} />
      <ReservationReviewArea localDate={localDate} partySize={partySize} selectedSlot={selectedSlot} customer={customer} newsletterAction={newsletterAction} />
      <ReservationFeedback feedback={feedback} recovery={recovery} pending={pending} onRetry={() => sendReservation(recovery.body)} onAbandon={() => { setRecovery(null); setFeedback(null) }} onRefresh={feedback?.title === 'Reservation time unavailable' ? checkAvailability : null} />
      <div className="submit-area">
        {eligibilityReason && <p className="submit-guidance">To reserve: {eligibilityReason}</p>}
        <button className="button button--primary" type="submit" disabled={!eligible}>{pending ? 'Reserving your table…' : 'Reserve table'}</button>
        {pending && <p role="status">Reserving your table…</p>}
      </div>
    </form>
  )
}

function ContextSummary({ context }) {
  return (
    <section className="context-summary form-card" aria-labelledby="context-heading">
      <div><h2 id="context-heading">Current reservation policy</h2><p>Times follow {context.restaurant_timezone}. Availability is provisional until booking succeeds.</p></div>
      <dl className="context-facts">
        <div><dt>Start interval</dt><dd>{context.reservation_policy.start_interval_minutes} minutes</dd></div>
        <div><dt>Dining time</dt><dd>{context.reservation_policy.reservation_duration_minutes} minutes</dd></div>
        <div><dt>Same-day lead</dt><dd>{context.reservation_policy.same_day_lead_minutes} minutes</dd></div>
        <div><dt>Advance window</dt><dd>{context.reservation_policy.advance_window_days} days</dd></div>
      </dl>
      <details className="dining-hours">
        <summary>Current dining hours</summary>
        <div className="dining-hours__list">
          {context.weekday_hours.map((entry) => (
            <p className="dining-hours__row" key={entry.iso_weekday}>
              <span>{DAY_NAMES[entry.iso_weekday - 1]}:</span>
              <span className="dining-hours__time">{formatClockTime(entry.opens_at_local)}–{formatClockTime(entry.closes_at_local)}</span>
            </p>
          ))}
        </div>
      </details>
    </section>
  )
}

export function AvailabilityArea({ availability, selectedStart, setSelectedStart, slotNotice, messageRef, onRetry, locked }) {
  return (
    <fieldset className="form-card availability-area" disabled={locked || availability.status === 'loading'} aria-busy={availability.status === 'loading'}>
      <legend>2. Choose a time</legend>
      {slotNotice && <p className="required-action" role="alert" tabIndex="-1" ref={messageRef}>{slotNotice}</p>}
      {availability.status === 'idle' && <p>Choose a valid date and party size, then check availability.</p>}
      {availability.status === 'loading' && <p role="status">Checking the complete schedule…</p>}
      {availability.status === 'error' && <StatusPanel tone="error" title="Times could not be loaded" role="alert" actions={availability.retryable ? <button className="button button--secondary" type="button" onClick={onRetry}>Try again</button> : null}><p>{availability.retryable ? 'This read can be retried. No times are shown as current.' : 'This response cannot be retried unchanged. No times are shown as current.'}</p></StatusPanel>}
      {availability.status === 'ready' && availability.data.slots.length === 0 && <p role="status">No reservation times are offered for this date and party size.</p>}
      {availability.status === 'ready' && availability.data.slots.length > 0 && <>
        <p>Restaurant local time. Times are provisional and no table is held.</p>
        {availability.data.slots.every((slot) => !slot.available) && <p role="status">All offered times are currently unavailable. Choose another date or party size, or refresh.</p>}
        <div className="slot-grid">
          {availability.data.slots.map((slot) => (
            <label key={slot.starts_at_local} className={`slot-card${selectedStart === slot.starts_at_local ? ' is-selected' : ''}${!slot.available ? ' is-unavailable' : ''}`}>
              <input type="radio" name="reservation_slot" value={slot.starts_at_local} checked={selectedStart === slot.starts_at_local} disabled={!slot.available} onChange={() => setSelectedStart(slot.starts_at_local)} />
              <span><strong>{formatClockTime(slot.starts_at_local)}–{formatClockTime(slot.ends_at_local)}</strong><small>{slot.available ? selectedStart === slot.starts_at_local ? 'Selected' : 'Available' : 'Unavailable'}</small></span>
            </label>
          ))}
        </div>
      </>}
    </fieldset>
  )
}

export function CustomerAndReservationFormArea({ customer, update, blur, errors, locked, lookup, checked, choiceDirty, onChecked, onRetryLookup }) {
  const fields = [
    ['first_name', 'First name', 'given-name', false, 'text'], ['middle_initial', 'Middle initial', 'additional-name', true, 'text'], ['last_name', 'Last name', 'family-name', false, 'text'], ['email', 'Email', 'email', false, 'email'], ['confirmation_email', 'Confirm email', 'off', false, 'email'], ['phone', 'Phone', 'tel', true, 'tel'],
  ]
  const lookupText = lookup.state === 'waiting' || lookup.state === 'checking' ? 'Checking your current newsletter preference…' : lookup.state === 'matched' ? choiceDirty ? 'Stored status checked; your deliberate choice is retained.' : `Current preference: ${lookup.subscribed ? 'subscribed' : 'not subscribed'}.` : lookup.state === 'not_found' ? 'No existing newsletter preference was found.' : lookup.state === 'conflict' ? 'The entered identity details do not match our records.' : lookup.state === 'indeterminate' ? 'We could not check status. Retry later, or reserve without changing it.' : lookup.state === 'read_failure' ? 'Newsletter status is temporarily unavailable. Retry, or reserve without changing it.' : lookup.state === 'error' ? 'Newsletter status could not be checked. Correct service integration before retrying.' : 'Status not checked.'
  return (
    <fieldset className="form-card" disabled={locked}>
      <legend>3. Your details and newsletter preference</legend>
      <div className="form-grid">
        {fields.map(([id, label, autoComplete, optional, type]) => <FormField key={id} id={id} label={label} optional={optional} error={errors[id]}>
          {({ describedBy }) => <input id={id} type={type} autoComplete={autoComplete} value={customer[id]} onChange={(event) => update(id, event.target.value)} onBlur={() => blur(id)} aria-invalid={Boolean(errors[id])} aria-describedby={describedBy} required={!optional} maxLength={id === 'middle_initial' ? 1 : id.includes('email') ? 254 : id === 'phone' ? 32 : undefined} />}
        </FormField>)}
      </div>
      <div className="newsletter-choice">
        <label className="checkbox-row" htmlFor="reservation_newsletter"><input id="reservation_newsletter" type="checkbox" checked={checked} onChange={(event) => onChecked(event.target.checked)} /><span>Subscribe me to the Café Fausse newsletter</span></label>
        <p role="status">{lookupText}</p>
        {(lookup.state === 'indeterminate' || lookup.state === 'read_failure') && lookup.retryable && <button className="button button--secondary" type="button" onClick={onRetryLookup}>Retry newsletter status</button>}
        {!['matched', 'not_found'].includes(lookup.state) && choiceDirty && <p className="field-help">Your displayed choice is preserved but this booking will use no change until a current lookup succeeds.</p>}
      </div>
    </fieldset>
  )
}

export function ReservationReviewArea({ localDate, partySize, selectedSlot, customer, newsletterAction }) {
  return (
    <section className="form-card review-area" aria-labelledby="review-heading"><h2 id="review-heading">4. Review and reserve</h2><dl>
      <div><dt>Date</dt><dd>{localDate || 'Not selected'}</dd></div><div><dt>Time</dt><dd>{selectedSlot ? `${formatClockTime(selectedSlot.starts_at_local)}–${formatClockTime(selectedSlot.ends_at_local)}` : 'Not selected'}</dd></div><div><dt>Party size</dt><dd>{partySize || 'Not entered'}</dd></div><div><dt>Name</dt><dd>{[customer.first_name, customer.middle_initial, customer.last_name].filter(Boolean).join(' ') || 'Not entered'}</dd></div><div><dt>Newsletter action</dt><dd>{newsletterAction.replace('_', ' ')}</dd></div>
    </dl></section>
  )
}

export function ReservationFeedback({ feedback, recovery, pending, onRetry, onAbandon, onRefresh }) {
  if (!feedback) return null
  return <StatusPanel tone={feedback.tone} title={feedback.title} role="alert" actions={<>{onRefresh && <button className="button button--secondary" type="button" onClick={onRefresh}>Refresh times</button>}{recovery && <button className="button button--primary" type="button" onClick={onRetry} disabled={pending}>{pending ? 'Retrying the same reservation…' : 'Retry the same reservation'}</button>}{recovery && <button className="button button--secondary" type="button" onClick={onAbandon}>Leave unresolved</button>}</>}><p>{feedback.text}</p></StatusPanel>
}

export function ReservationConfirmationView({ result, restaurantTimezone, headingRef, onNew }) {
  const { confirmation, booking_result: bookingResult, phone_notice: phoneNotice } = result
  return (
    <section className="confirmation-view" aria-labelledby="confirmation-heading"><p className="eyebrow">Confirmed</p><h2 id="confirmation-heading" tabIndex="-1" ref={headingRef}>Reservation confirmed</h2>{bookingResult === 'exact_retry' && <p role="status">Your existing reservation was recovered.</p>}<dl>
      <div><dt>Name</dt><dd>{confirmation.customer_name}</dd></div><div><dt>Reference</dt><dd>{confirmation.reservation_reference}</dd></div><div><dt>Starts</dt><dd>{formatRestaurantDateTime(confirmation.starts_at, restaurantTimezone)}</dd></div><div><dt>Ends</dt><dd>{formatRestaurantDateTime(confirmation.ends_at, restaurantTimezone)}</dd></div><div><dt>Party size</dt><dd>{confirmation.party_size}</dd></div><div><dt>Assigned table{confirmation.assigned_table_numbers.length > 1 ? 's' : ''}</dt><dd>{confirmation.assigned_table_numbers.join(', ')}</dd></div><div><dt>Newsletter</dt><dd>{confirmation.newsletter_subscribed ? 'Subscribed' : 'Not subscribed'}</dd></div><div><dt>Restaurant</dt><dd>{confirmation.restaurant.address}<br />{confirmation.restaurant.phone}</dd></div>
    </dl>{phoneNotice && <p className="status-panel status-panel--information">{phoneNotice.message}</p>}<p>This on-screen confirmation does not indicate that email, SMS, or phone delivery occurred.</p><div className="action-group"><Link className="button button--primary" to="/">Return home</Link><button className="button button--secondary" type="button" onClick={onNew}>Make another reservation</button></div></section>
  )
}
