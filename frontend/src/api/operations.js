import { createContext, createElement, useContext } from 'react'
import { liveOperationClient } from './liveOperations.js'

const OperationContext = createContext(liveOperationClient)

export function OperationProvider({ client = liveOperationClient, children }) {
  return createElement(OperationContext.Provider, { value: client }, children)
}

export function useOperations() {
  return useContext(OperationContext)
}
