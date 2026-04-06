import type { ScanResult } from "@/lib/types";
import { decodeBase64Url, encodeBytesToBase64Url } from "@/lib/utils";

export function encodeResultPayload(result: ScanResult): string {
  const bytes = new TextEncoder().encode(JSON.stringify(result));
  return encodeBytesToBase64Url(bytes);
}

export function decodeResultPayload(value: string): ScanResult | null {
  try {
    const bytes = decodeBase64Url(value);
    const json = new TextDecoder().decode(bytes);
    return JSON.parse(json) as ScanResult;
  } catch {
    return null;
  }
}
