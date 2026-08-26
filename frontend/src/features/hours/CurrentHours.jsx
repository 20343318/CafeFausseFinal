import { useCallback, useEffect, useState } from 'react'
import { useOperations } from '../../api/operations.js'
import { StatusPanel } from '../../components/FormPrimitives.jsx'

const DAY_NAMES = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

function timeLabel(localTime) {
  const [hourText, minute] = localTime.split(':')
  const hour = Number(hourText)
  const suffix = hour >= 12 ? 'PM' : 'AM'
  const displayHour = hour % 12 || 12
  return `${displayHour}:${minute} ${suffix}`
}

export function CurrentHours() {
  const operations = useOperations()
  const [state, setState] = useState({ status: 'loading' })

  const load = useCallback(async () => {
    setState({ status: 'loading' })
    try {
      const context = await operations.getReservationContext()
      setState({ status: 'ready', context })
    } catch {
      setState({ status: 'error' })
    }
  }, [operations])

  useEffect(() => {
    load()
  }, [load])

  if (state.status === 'loading') return <p role="status">Loading current dining hours&hellip;</p>
  if (state.status === 'error') {
    return (
      <StatusPanel
        tone="error"
        title="Current hours are unavailable"
        role="alert"
        actions={<button className="button button--secondary" type="button" onClick={load}>Try again</button>}
      >
        <p>We could not load current dining hours. No schedule has been assumed.</p>
      </StatusPanel>
    )
  }

  return (
    <div data-current-hours-source="reservation-context">
      <p className="field-help">Restaurant local time ({state.context.restaurant_timezone})</p>
      {state.context.weekday_hours.map((entry) => (
        <p key={entry.iso_weekday}>
          {DAY_NAMES[entry.iso_weekday - 1]}: {timeLabel(entry.opens_at_local)}&ndash;{timeLabel(entry.closes_at_local)}
        </p>
      ))}
    </div>
  )
}
