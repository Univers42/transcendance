import styles from '../Button.module.scss';

interface ButtonContentProps {
  label?: string;
  children?: React.ReactNode;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const ButtonContent = ({ label, children, leftIcon, rightIcon }: ButtonContentProps) => (
  <>
    {leftIcon && <span className={styles['btn__icon--left']}>{leftIcon}</span>}
    {label ? <span>{label}</span> : children}
    {rightIcon && <span className={styles['btn__icon--right']}>{rightIcon}</span>}
  </>
);