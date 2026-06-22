import type { NodeProps } from '@xyflow/react';
import { C4Base } from './C4Base';

export function C4System(props: NodeProps) {
  return (
    <C4Base
      {...props}
      typeLabel="Software System"
      colorClass="bg-[#1168bd]"
      borderClass="border-[#0b4884]"
    />
  );
}
