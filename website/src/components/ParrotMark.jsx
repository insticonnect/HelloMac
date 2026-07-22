/** Inline "Mitthu" parrot logo (scales with its container). */
export default function ParrotMark() {
  return (
    <svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <defs>
        <linearGradient id="lBody" x1="10" y1="12" x2="48" y2="56" gradientUnits="userSpaceOnUse">
          <stop stopColor="#6ee7b7" />
          <stop offset=".55" stopColor="#10b981" />
          <stop offset="1" stopColor="#047857" />
        </linearGradient>
        <linearGradient id="lBeak" x1="38" y1="24" x2="56" y2="42" gradientUnits="userSpaceOnUse">
          <stop stopColor="#fbbf24" />
          <stop offset="1" stopColor="#f97316" />
        </linearGradient>
      </defs>
      <g fill="#34d399">
        <ellipse cx="24" cy="9" rx="3.2" ry="7" transform="rotate(-24 24 9)" />
        <ellipse cx="30" cy="7" rx="3.2" ry="7.5" transform="rotate(-6 30 7)" />
        <ellipse cx="36" cy="9" rx="3.2" ry="7" transform="rotate(12 36 9)" />
      </g>
      <ellipse cx="30" cy="34" rx="19" ry="18" fill="url(#lBody)" />
      <ellipse cx="24" cy="40" rx="8" ry="7" fill="#a7f3d0" opacity=".5" />
      <path d="M43 28c8 0 13 4 12 10-.6 5-6 8-11 6 3-2 4-5 2-7-3 0-5-1-6-4Z" fill="url(#lBeak)" />
      <path d="M44 39c3 1 6 .6 8-1" stroke="#c2410c" strokeWidth="1.4" strokeLinecap="round" fill="none" opacity=".5" />
      <circle cx="35" cy="28" r="5.4" fill="#fff" />
      <circle cx="36" cy="28.5" r="3" fill="#0a1512" />
      <circle cx="37.3" cy="27.3" r="1" fill="#fff" />
    </svg>
  )
}
