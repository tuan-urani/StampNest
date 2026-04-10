import React from 'react';
import { cn } from '@/src/lib/utils';

interface StampProps {
  src: string;
  className?: string;
  alt?: string;
}

/**
 * Stamp component using the user's CUSTOM DRAWN SVG structure.
 * This version uses the ultra-detailed path provided by the user.
 */
export const Stamp: React.FC<StampProps> = ({ src, className, alt }) => {
  const userPath = "M122.77,9.66V6.75h-5.61a3.12,3.12,0,1,1-6.24,0h-2.75a3.12,3.12,0,0,1-6.24,0H99.18a3.12,3.12,0,0,1-6.24,0H90.19a3.12,3.12,0,0,1-6.24,0H81.2a3.12,3.12,0,0,1-6.24,0H72.21a3.12,3.12,0,1,1-6.24,0H63.22a3.12,3.12,0,1,1-6.24,0H54.23a3.13,3.13,0,0,1-6.25,0H45.24a3.13,3.13,0,0,1-6.25,0H36.25a3.13,3.13,0,0,1-6.25,0H27.26a3.13,3.13,0,0,1-6.25,0H18.27a3.13,3.13,0,0,1-6.25,0H7.23V9.62a3.13,3.13,0,0,1,0,6.25v2.75a3.12,3.12,0,0,1,0,6.24v2.75a3.12,3.12,0,0,1,0,6.24V36.6a3.12,3.12,0,0,1,0,6.24v2.75a3.12,3.12,0,1,1,0,6.24v2.75a3.12,3.12,0,0,1,0,6.24v2.75a3.12,3.12,0,0,1,0,6.24v2.75a3.12,3.12,0,1,1,0,6.24v2.75a3.12,3.12,0,0,1,0,6.24v2.75a3.12,3.12,0,1,1,0,6.24v2.75a3.12,3.12,0,1,1,0,6.24v2.75a3.13,3.13,0,0,1,0,6.25v2.74a3.13,3.13,0,0,1,0,6.25v2.74a3.13,3.13,0,0,1,0,6.25v2.74a3.13,3.13,0,0,1,0,6.25v2.74a3.13,3.13,0,0,1,0,6.25v2.52H12a3.13,3.13,0,0,1,6.25,0H21a3.13,3.13,0,0,1,6.25,0H30a3.13,3.13,0,0,1,6.25,0H39a3.13,3.13,0,0,1,6.25,0H48a3.13,3.13,0,0,1,6.25,0H57a3.12,3.12,0,1,1,6.24,0H66a3.12,3.12,0,1,1,6.24,0H75a3.12,3.12,0,0,1,6.24,0H84a3.12,3.12,0,0,1,6.24,0h2.75a3.12,3.12,0,0,1,6.24,0h2.75a3.12,3.12,0,1,1,6.24,0h2.75a3.12,3.12,0,1,1,6.24,0h5.61v-2.56a3.11,3.11,0,0,1,0-6.17V141.7a3.11,3.11,0,0,1,0-6.17v-2.82a3.11,3.11,0,0,1,0-6.17v-2.82a3.11,3.11,0,0,1,0-6.17v-2.82a3.11,3.11,0,0,1,0-6.17v-2.82a3.11,3.11,0,0,1,0-6.17V96.74a3.1,3.1,0,0,1,0-6.16V87.75a3.1,3.1,0,0,1,0-6.16V78.76a3.1,3.1,0,0,1,0-6.16V69.77a3.1,3.1,0,0,1,0-6.16V60.78a3.1,3.1,0,0,1,0-6.16V51.79a3.1,3.1,0,0,1,0-6.16V42.8a3.1,3.1,0,0,1,0-6.16V33.81a3.11,3.11,0,0,1,0-6.17V24.82a3.11,3.11,0,0,1,0-6.17V15.83a3.11,3.11,0,0,1,0-6.17Z";

  return (
    <div className={cn("relative inline-block", className)}>
      <svg
        viewBox="0 0 130 160"
        className="w-full h-auto block"
        role="presentation"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <clipPath id="user-stamp-clip">
            <path d={userPath} />
          </clipPath>
        </defs>

        {/* Paper Background with your detailed path */}
        <path
          fill="white"
          d={userPath}
        />

        {/* The Image inside the stamp frame */}
        <image
          href={src}
          width="130"
          height="160"
          clipPath="url(#user-stamp-clip)"
          preserveAspectRatio="xMidYMid slice"
          onError={(e) => {
            (e.currentTarget as SVGImageElement).setAttribute('href', 'https://placehold.co/600x800/f8f5ed/a0a09c?text=Stamp+Not+Found');
          }}
        />
      </svg>
    </div>
  );
};
