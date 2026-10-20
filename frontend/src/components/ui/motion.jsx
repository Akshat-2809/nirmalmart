import { motion } from 'framer-motion';

export const ease = [0.22, 1, 0.36, 1];

export const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  show: { opacity: 1, y: 0, transition: { duration: 0.6, ease } },
};

export const stagger = (gap = 0.07, delay = 0) => ({
  hidden: {},
  show: { transition: { staggerChildren: gap, delayChildren: delay } },
});

/** Fades + lifts its children into view once, when scrolled to. */
export function Reveal({ children, className, delay = 0, y = 24, as = 'div' }) {
  const M = motion[as];
  return (
    <M
      className={className}
      initial={{ opacity: 0, y }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-60px' }}
      transition={{ duration: 0.7, ease, delay }}
    >
      {children}
    </M>
  );
}

/** Staggers direct <motion.* variants={fadeUp}> children as the group scrolls into view. */
export function Stagger({ children, className, gap = 0.07 }) {
  return (
    <motion.div className={className} variants={stagger(gap)} initial="hidden" whileInView="show"
      viewport={{ once: true, margin: '-40px' }}>
      {children}
    </motion.div>
  );
}

export function PageTransition({ children }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, ease }}
    >
      {children}
    </motion.div>
  );
}
