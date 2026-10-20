import { useState } from 'react';
import { cn } from '../../lib/cn';

export const STATES = [
  'Andaman and Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chandigarh', 'Chhattisgarh',
  'Dadra and Nagar Haveli and Daman and Diu', 'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir',
  'Jharkhand', 'Karnataka', 'Kerala', 'Ladakh', 'Lakshadweep', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
  'Mizoram', 'Nagaland', 'Odisha', 'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
  'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
];

const EMPTY = { label: 'Home', full_name: '', phone: '', address_line1: '', address_line2: '', city: '', state: '', postal_code: '', is_default: false };

const validate = (a) => {
  const e = {};
  if (a.full_name.trim().length < 2) e.full_name = 'Enter the recipient’s name';
  if (!/^[6-9]\d{9}$/.test(a.phone.replace(/\D/g, '').slice(-10))) e.phone = 'Enter a valid 10-digit mobile number';
  if (a.address_line1.trim().length < 3) e.address_line1 = 'Enter house no. and street';
  if (a.city.trim().length < 2) e.city = 'Enter city';
  if (!a.state) e.state = 'Select state';
  if (!/^[1-9]\d{5}$/.test(a.postal_code)) e.postal_code = 'Enter a valid 6-digit pincode';
  return e;
};

export default function AddressForm({ initial, onSubmit, submitting, submitLabel = 'Save address', onCancel }) {
  const [a, setA] = useState({ ...EMPTY, ...initial });
  const [errors, setErrors] = useState({});
  const field = (k) => ({
    value: a[k] ?? '', 'aria-invalid': !!errors[k],
    onChange: (e) => { setA({ ...a, [k]: e.target.value }); setErrors({ ...errors, [k]: undefined }); },
    className: cn('input', errors[k] && 'border-danger focus:border-danger focus:ring-danger/15'),
  });
  const Err = ({ k }) => (errors[k] ? <p className="mt-1 text-xs text-danger">{errors[k]}</p> : null);

  const submit = (e) => {
    e.preventDefault();
    const errs = validate(a);
    setErrors(errs);
    if (!Object.keys(errs).length) onSubmit({ ...a, phone: a.phone.replace(/\D/g, '').slice(-10) });
  };

  return (
    <form onSubmit={submit} className="grid gap-4 sm:grid-cols-2" noValidate>
      <div className="flex gap-2 sm:col-span-2">
        {['Home', 'Work', 'Other'].map((l) => (
          <button type="button" key={l} onClick={() => setA({ ...a, label: l })} className={cn('chip h-8', a.label === l && 'chip-active')}>{l}</button>
        ))}
      </div>
      <div><label className="label">Full name</label><input {...field('full_name')} autoComplete="name" /><Err k="full_name" /></div>
      <div><label className="label">Mobile number</label><input {...field('phone')} inputMode="tel" autoComplete="tel" placeholder="10-digit number" /><Err k="phone" /></div>
      <div className="sm:col-span-2"><label className="label">House no., building, street</label><input {...field('address_line1')} autoComplete="address-line1" /><Err k="address_line1" /></div>
      <div className="sm:col-span-2"><label className="label">Area, landmark (optional)</label><input {...field('address_line2')} autoComplete="address-line2" /></div>
      <div><label className="label">Pincode</label><input {...field('postal_code')} inputMode="numeric" maxLength={6} autoComplete="postal-code" /><Err k="postal_code" /></div>
      <div><label className="label">City</label><input {...field('city')} autoComplete="address-level2" /><Err k="city" /></div>
      <div className="sm:col-span-2">
        <label className="label">State</label>
        <select {...field('state')} autoComplete="address-level1"><option value="">Select state</option>{STATES.map((s) => <option key={s}>{s}</option>)}</select>
        <Err k="state" />
      </div>
      <label className="flex items-center gap-2 text-sm text-ink-soft sm:col-span-2">
        <input type="checkbox" checked={a.is_default} onChange={(e) => setA({ ...a, is_default: e.target.checked })} className="h-4 w-4 accent-[rgb(var(--brand))]" />
        Make this my default address
      </label>
      <div className="flex gap-2 sm:col-span-2">
        {onCancel && <button type="button" className="btn-outline" onClick={onCancel}>Cancel</button>}
        <button className="btn-dark flex-1" disabled={submitting}>{submitting ? 'Saving…' : submitLabel}</button>
      </div>
    </form>
  );
}
