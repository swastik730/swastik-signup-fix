/** Username-based auth helpers (no real email address required). */

export const USERNAME_DOMAIN = "boardbuddy.app";

export const RECOVERY_QUESTIONS = [
  "Aapke best friend ka naam?",
  "Aapke school ka naam?",
  "Aapka favourite subject?",
  "Aapke pet / favourite animal ka naam?",
];

export function normalizeUsername(value: string): string {
  return value.trim().toLowerCase();
}

export function isValidUsername(value: string): boolean {
  return /^[a-z0-9._]{3,20}$/.test(normalizeUsername(value));
}

/** Login field accepts a username, or an email for the owner account. */
export function identifierToEmail(value: string): string {
  const raw = value.trim();
  if (raw.includes("@")) return raw.toLowerCase();
  return `${normalizeUsername(raw)}@${USERNAME_DOMAIN}`;
}

/** Deterministic hash of the secret answer — the plain answer never leaves the device. */
export async function hashAnswer(username: string, answer: string): Promise<string> {
  const data = new TextEncoder().encode(
    `${normalizeUsername(username)}:${answer.trim().toLowerCase()}`,
  );
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
