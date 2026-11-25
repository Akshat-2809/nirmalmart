import { fadeUp, Stagger } from './ui/motion';
import { motion } from 'framer-motion';

/** Numbered sections of bullet points, for the privacy, terms and account-deletion pages */
export function LegalSections({ sections }) {
  return (
    <Stagger className="mt-8 space-y-4">
      {sections.map(([title, points], i) => (
        <motion.section key={title} variants={fadeUp} className="card p-5 sm:p-6">
          <h2 className="font-display text-lg font-bold">
            <span className="mr-2 text-brand">{i + 1}.</span>{title}
          </h2>
          <ul className="mt-3 list-disc space-y-1.5 pl-5 text-sm leading-relaxed text-ink-soft marker:text-brand">
            {points.map((p) => <li key={p}>{p}</li>)}
          </ul>
        </motion.section>
      ))}
    </Stagger>
  );
}
