import { Component } from 'react'

export class AppErrorBoundary extends Component {
  state = { hasError: false }

  static getDerivedStateFromError() {
    return { hasError: true }
  }

  render() {
    if (this.state.hasError) {
      return (
        <main id="main-content" className="error-page container">
          <div className="error-page__panel" role="alert" aria-labelledby="global-error-heading">
            <p className="eyebrow">Something went wrong</p>
            <h1 id="global-error-heading">We couldn’t display this page</h1>
            <p>Please return to the Home page and try again.</p>
            <a className="button button--primary" href="/">Return to Home</a>
          </div>
        </main>
      )
    }

    return this.props.children
  }
}
