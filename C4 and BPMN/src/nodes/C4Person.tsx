import type { NodeProps } from '@xyflow/react';
import { C4Base } from './C4Base';

const PersonIcon = () => (
  <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
    <circle cx="12" cy="7" r="4" />
    <path d="M4 21c0-4.4 3.6-8 8-8s8 3.6 8 8" />
  </svg>
);

export function C4Person(props: NodeProps) {
  return (
    <C4Base
      {...props}
      typeLabel="Person"
      colorClass="bg-[#08427b]"
      borderClass="border-[#052e56]"
      rounded
      icon={<PersonIcon />}
    />
  );
}
