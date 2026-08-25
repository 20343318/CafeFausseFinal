import { createContext, createElement, useContext } from 'react'
import { cloneFixture, reservationContextFixture, resolveAvailability, resolveNewsletterPreference, resolveNewsletterStatus, resolveReservation } from './contractFixtures.js'

const pause = (milliseconds = 120) => new Promise((resolve) => setTimeout(resolve, milliseconds))

export const mockOperationClient = Object.freeze({
  async getReservationContext() {
    await pause()
    return cloneFixture(reservationContextFixture)
  },
  async getReservationAvailability({ local_date, party_size }) {
    await pause()
    return resolveAvailability({ local_date, party_size })
  },
  async queryNewsletterStatus(body) {
    await pause()
    return resolveNewsletterStatus(body)
  },
  async setNewsletterPreference(body) {
    await pause()
    return resolveNewsletterPreference(body)
  },
  async createReservation(body) {
    await pause()
    return resolveReservation(body)
  },
})

const OperationContext = createContext(mockOperationClient)

export function OperationProvider({ client = mockOperationClient, children }) {
  return createElement(OperationContext.Provider, { value: client }, children)
}

export function useOperations() {
  return useContext(OperationContext)
}
