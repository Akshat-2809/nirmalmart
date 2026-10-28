import { Facebook, Instagram, Youtube } from 'lucide-react';

// Store contact details, shared by the footer and the Contact us page
export const PHONE = { display: '+91 74982 99375', tel: '+917498299375', wa: '917498299375' };

// UPI QR payments: customers pay to this QR and send proof on WhatsApp; the admin then marks the order paid
export const PAYMENT = {
  qr: '/upi-qr.jpg',
  upiId: 'vyapar.175693393199@hdfcbank',
  payee: 'NIRMAL MART',
  wa: '919022230687',
  waDisplay: '+91 90222 30687',
};

export const SOCIAL = [
  ['Instagram', Instagram, 'https://www.instagram.com/nirmalmart09', '@nirmalmart09'],
  ['Facebook', Facebook, 'https://www.facebook.com/share/1GUyQxBTdf/', 'Nirmal Mart'],
  ['YouTube', Youtube, 'https://www.youtube.com/@NirmalMart', '@NirmalMart'],
];
