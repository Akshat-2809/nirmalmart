// Shared input rules (mirrors backend/app/schemas/common.py). Unicode letter classes so
// customers can also type names/cities in Marathi.

/** Keeps only letters (any script), spaces and . ' - ; no leading space. */
export const cleanName = (v) => v.replace(/[^\p{L}\p{M} .'-]/gu, '').replace(/^[\s.'-]+/, '').replace(/\s{2,}/g, ' ').slice(0, 60);
/** Keeps only letters, spaces, . and - */
export const cleanCity = (v) => v.replace(/[^\p{L}\p{M} .-]/gu, '').replace(/^[\s.-]+/, '').replace(/\s{2,}/g, ' ').slice(0, 60);
/** Digits only, max 10; a pasted +91 / 0 prefix is dropped. */
export const cleanMobile = (v) => {
  let d = v.replace(/\D/g, '');
  if (d.length > 10 && d.startsWith('91')) d = d.slice(2);
  if (d.length > 10 && d.startsWith('0')) d = d.slice(1);
  return d.slice(0, 10);
};
export const cleanPincode = (v) => v.replace(/\D/g, '').slice(0, 6);

export const isName = (v) => /^[\p{L}\p{M}][\p{L}\p{M} .'-]*$/u.test(v.trim()) && v.trim().length >= 2;
export const isCity = (v) => /^[\p{L}\p{M}][\p{L}\p{M} .-]*$/u.test(v.trim()) && v.trim().length >= 2;
export const isMobile = (v) => /^[6-9]\d{9}$/.test(v);
export const isPincode = (v) => /^[1-9]\d{5}$/.test(v);
