import { useEffect, useRef, useState } from 'react'
import { identityBody, identityIsEligible } from './validation.js'

export function useNewsletterLookup({ values, query, choiceVersion, onUntouchedResult, retryVersion = 0 }) {
  const [lookup, setLookup] = useState({ state: 'not_checked' })
  const sequence = useRef(0)
  const latest = useRef({ values, choiceVersion })
  latest.current = { values, choiceVersion }

  useEffect(() => {
    const requestSequence = ++sequence.current
    if (!identityIsEligible(values)) {
      setLookup({ state: 'not_checked' })
      return undefined
    }
    const snapshot = identityBody(values)
    const snapshotKey = JSON.stringify(snapshot)
    const startChoiceVersion = choiceVersion
    setLookup({ state: 'waiting' })
    const timer = setTimeout(async () => {
      setLookup({ state: 'checking' })
      try {
        const result = await query(snapshot)
        const currentKey = identityIsEligible(latest.current.values) ? JSON.stringify(identityBody(latest.current.values)) : ''
        if (requestSequence !== sequence.current || currentKey !== snapshotKey) return
        setLookup({ state: result.status, subscribed: result.subscribed })
        if (startChoiceVersion === 0 && latest.current.choiceVersion === startChoiceVersion) onUntouchedResult(result)
      } catch (cause) {
        const currentKey = identityIsEligible(latest.current.values) ? JSON.stringify(identityBody(latest.current.values)) : ''
        if (requestSequence !== sequence.current || currentKey !== snapshotKey) return
        const error = cause.response?.error
        if (error?.code === 'customer_identity_conflict' || error?.code === 'middle_initial_conflict') {
          setLookup({ state: 'conflict', code: error.code })
        } else if (!error || error.code === 'newsletter_status_indeterminate') {
          setLookup({ state: 'indeterminate', code: error?.code || 'transport_failure', retryable: error?.retryable !== false })
        } else if (error.retryable) {
          setLookup({ state: 'read_failure', code: error.code, retryable: true })
        } else {
          setLookup({ state: 'error', code: error.code, retryable: false })
        }
      }
    }, 400)
    return () => clearTimeout(timer)
  }, [values.first_name, values.middle_initial, values.last_name, values.email, values.confirmation_email, query, onUntouchedResult, retryVersion])

  return lookup
}
