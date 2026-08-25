import { Route, Routes } from 'react-router'
import { AppErrorBoundary } from './AppErrorBoundary.jsx'
import { AppShell } from './layout/AppShell.jsx'
import { AboutPage } from './pages/AboutPage.jsx'
import { GalleryPage } from './pages/GalleryPage.jsx'
import { HomePage } from './pages/HomePage.jsx'
import { MenuPage } from './pages/MenuPage.jsx'
import { NotFoundPage } from './pages/NotFoundPage.jsx'
import { ReservationsPage } from './pages/ReservationsPage.jsx'
import { OperationProvider, mockOperationClient } from './api/operations.js'

export function App({ operations = mockOperationClient }) {
  return (
    <AppErrorBoundary>
      <OperationProvider client={operations}>
        <Routes>
          <Route element={<AppShell />}>
            <Route index element={<HomePage />} />
            <Route path="menu" element={<MenuPage />} />
            <Route path="reservations" element={<ReservationsPage />} />
            <Route path="about" element={<AboutPage />} />
            <Route path="gallery" element={<GalleryPage />} />
            <Route path="*" element={<NotFoundPage />} />
          </Route>
        </Routes>
      </OperationProvider>
    </AppErrorBoundary>
  )
}
