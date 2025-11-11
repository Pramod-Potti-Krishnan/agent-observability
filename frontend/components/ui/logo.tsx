export function GarudaiLogo({ className = "h-8 w-8" }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 100 100"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      {/* Eagle silhouette with modern geometric style */}
      <g>
        {/* Head */}
        <circle cx="50" cy="35" r="8" fill="currentColor" />

        {/* Eye - watchful */}
        <circle cx="52" cy="34" r="2" fill="white" />

        {/* Body */}
        <path
          d="M 50 43 L 50 65 L 45 70 L 50 75 L 55 70 Z"
          fill="currentColor"
        />

        {/* Left Wing - spread wide */}
        <path
          d="M 45 50 Q 20 45 15 55 Q 18 58 25 55 Q 35 52 45 55 Z"
          fill="currentColor"
          opacity="0.9"
        />

        {/* Right Wing - spread wide */}
        <path
          d="M 55 50 Q 80 45 85 55 Q 82 58 75 55 Q 65 52 55 55 Z"
          fill="currentColor"
          opacity="0.9"
        />

        {/* Circuit pattern overlay on wings - tech element */}
        <path
          d="M 25 52 L 30 52 M 28 50 L 28 54"
          stroke="currentColor"
          strokeWidth="1"
          opacity="0.5"
        />
        <path
          d="M 70 52 L 75 52 M 72.5 50 L 72.5 54"
          stroke="currentColor"
          strokeWidth="1"
          opacity="0.5"
        />

        {/* Tail feathers */}
        <path
          d="M 50 75 L 47 85 L 50 83 L 53 85 Z"
          fill="currentColor"
          opacity="0.8"
        />
      </g>
    </svg>
  )
}
