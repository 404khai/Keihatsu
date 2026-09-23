import Image from "next/image";
import Link from "next/link";

const downloadUrl =
  "https://github.com/grvt8/Keihatsu/releases/download/v1.0.0/keihatsu-v1.0.0.apk";

export default function NotFound() {
  return (
    <main className="not-found-page">
      <nav className="not-found-nav" aria-label="404 navigation">
        <Link className="not-found-brand font-comic" href="/" aria-label="Keihatsu home">
          <Image src="/404-brand.png" alt="" width={44} height={44} priority />
          <span>KEIHATSU</span>
        </Link>

        <div className="not-found-nav__links">
          <Link href="/#reader">Reader</Link>
          <Link href="/#features">Features</Link>
          <Link href="/#community">Community</Link>
          <Link className="not-found-pill not-found-pill--small" href="/">
            Back to home <span aria-hidden="true">↗</span>
          </Link>
        </div>
      </nav>

      <section className="not-found-hero">
        <div className="not-found-copy">
          <div className="not-found-eyebrow">
            <span aria-hidden="true" />
            Page not found
          </div>
          <h1 className="font-comic">
            This chapter
            <br />
            went missing.
          </h1>
          <p>
            We looked everywhere, but this page slipped between the panels. Let&apos;s
            get you back to something worth reading.
          </p>
          <div className="not-found-actions">
            <Link className="not-found-pill" href="/">
              Back to home <span aria-hidden="true">↗</span>
            </Link>
            <a className="not-found-pill not-found-pill--secondary" href={downloadUrl} download>
              Download App <span aria-hidden="true">↓</span>
            </a>
          </div>
          <div className="not-found-paw" aria-hidden="true">
            <svg viewBox="0 0 105 99" role="presentation">
              <path d="M100 50C100 100 100 100 50 100C0 100 0 100 0 50C0 0 0 0 50 0C100 0 100 0 100 50Z" fill="#F9F2EE" />
              <g fill="#FFDAA0">
                <circle cx="31.7" cy="44.728" r="14.365" />
                <circle cx="43.806" cy="37.6" r="13.316" />
                <circle cx="60.921" cy="37.6" r="15.602" />
                <circle cx="73.028" cy="44.728" r="12.593" />
                <path d="M77.774 49.777C78.036 55.529 75.621 63.499 71.39 67.766 67.148 72.032 58.475 75.596 52.364 75.379 46.253 75.161 38.903 70.726 34.713 66.459 30.534 62.192 28.046 56.084 27.258 49.777 26.471 43.471 25.809 32.69 29.999 28.621 34.178 24.552 45.717 24.592 52.364 25.364 59 26.136 65.594 29.185 69.825 33.254 74.067 37.323 77.511 44.025 77.774 49.777Z" />
              </g>
              <path d="M43.901 46.886C44.3 52.589 44.3 52.589 41.801 52.747 39.302 52.896 39.302 52.896 38.913 47.203 38.514 41.501 38.514 41.501 41.013 41.352 43.502 41.194 43.502 41.194 43.901 46.886Z" fill="#140E06" />
              <path d="M62.255 47.431C63.074 53.688 63.074 53.688 60.407 53.995 57.74 54.302 57.74 54.302 56.931 48.045 56.123 41.798 56.123 41.798 58.79 41.491 61.446 41.184 61.446 41.184 62.255 47.431Z" fill="#140E06" />
            </svg>
          </div>
        </div>

        <div className="not-found-art" aria-label="Error 404, no chapter here">
          <div className="not-found-route">Try another route <span>→</span></div>
          <div className="not-found-shape not-found-shape--lilac">?</div>
          <div className="not-found-shape not-found-shape--sky" />
          <div className="not-found-card">
            <span>KEIHATSU / ARCHIVE</span>
            <strong className="font-comic">404</strong>
            <small><i /> No chapter here</small>
          </div>
        </div>

        <Image
          className="not-found-mascot"
          src="/404-mascot.png"
          alt=""
          width={433}
          height={419}
          priority
        />
      </section>
    </main>
  );
}
