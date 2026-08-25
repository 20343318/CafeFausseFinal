import { render } from '@testing-library/react'
import { MemoryRouter } from 'react-router'
import { App } from '../App.jsx'

export function renderApp(path = '/', operations) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <App operations={operations} />
    </MemoryRouter>,
  )
}
