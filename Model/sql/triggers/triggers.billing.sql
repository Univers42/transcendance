-- ============================================================================
-- triggers.billing.sql — Triggers for Plans, Subscriptions, Invoices, Payments
-- ============================================================================
--
-- DOMAIN: Automates billing lifecycle — invoice totals, promo redemptions,
-- subscription state transitions, and payment reconciliation.
--
-- TRIGGERS:
--   1. fn_invoice_compute_total         — Auto-compute total from components
--   2. fn_subscription_promotion_redeem — Increment promo.current_redemptions
--   3. fn_subscription_set_cancelled_at — Stamp cancelled_at on cancellation
--   4. fn_payment_update_invoice_status — Mark invoice paid when fully paid
--   5. fn_validate_promotion_active     — Block expired/exhausted promos
--
-- EXECUTION ORDER: Run AFTER triggers.utility.sql.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_invoice_compute_total()
-- ─────────────────────────────────────────────────────────────────────────────
-- Automatically computes total_amount = subtotal - discount + tax.
-- Fires on INSERT and UPDATE of amount columns to keep the invariant.
--
-- FIRES: BEFORE INSERT OR UPDATE ON invoices (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_invoice_compute_total()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.total_amount := NEW.subtotal_amount - NEW.discount_amount + NEW.tax_amount;

    IF NEW.total_amount < 0 THEN
        NEW.total_amount := 0;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_invoices_compute_total
    BEFORE INSERT OR UPDATE OF subtotal_amount, discount_amount, tax_amount ON invoices
    FOR EACH ROW EXECUTE FUNCTION fn_invoice_compute_total();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_subscription_promotion_redeem()
-- ─────────────────────────────────────────────────────────────────────────────
-- When a subscription is created with a promotion_id, increments
-- promotions.current_redemptions. This tracks how many times a promo
-- code has been used.
--
-- FIRES: AFTER INSERT ON subscriptions (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_subscription_promotion_redeem()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.promotion_id IS NOT NULL THEN
        UPDATE promotions
           SET current_redemptions = current_redemptions + 1
         WHERE id = NEW.promotion_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_subscriptions_redeem_promo
    AFTER INSERT ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION fn_subscription_promotion_redeem();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_subscription_set_cancelled_at()
-- ─────────────────────────────────────────────────────────────────────────────
-- Stamps cancelled_at when subscription status transitions to 'cancelled'.
-- Clears cancelled_at if subscription is reactivated.
--
-- FIRES: BEFORE UPDATE ON subscriptions (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_subscription_set_cancelled_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.status = 'cancelled' AND OLD.status <> 'cancelled' THEN
        NEW.cancelled_at := now();
    ELSIF NEW.status <> 'cancelled' AND OLD.status = 'cancelled' THEN
        NEW.cancelled_at := NULL;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_subscriptions_set_cancelled_at
    BEFORE UPDATE OF status ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION fn_subscription_set_cancelled_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_payment_update_invoice_status()
-- ─────────────────────────────────────────────────────────────────────────────
-- When a payment succeeds, checks if the total paid covers the invoice.
-- If fully paid, marks the invoice as 'paid' and stamps paid_at.
--
-- FIRES: AFTER INSERT OR UPDATE ON payments (row-level)
-- CONDITION: When payment status = 'succeeded'
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_payment_update_invoice_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total_paid INT;
    v_invoice_total INT;
BEGIN
    SELECT COALESCE(SUM(amount - refund_amount), 0)
      INTO v_total_paid
      FROM payments
     WHERE invoice_id = NEW.invoice_id
       AND status = 'succeeded';

    SELECT total_amount INTO v_invoice_total
      FROM invoices WHERE id = NEW.invoice_id;

    IF v_total_paid >= v_invoice_total THEN
        UPDATE invoices
           SET status  = 'paid',
               paid_at = now()
         WHERE id = NEW.invoice_id
           AND status <> 'paid';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_payments_update_invoice
    AFTER INSERT OR UPDATE OF status ON payments
    FOR EACH ROW
    WHEN (NEW.status = 'succeeded')
    EXECUTE FUNCTION fn_payment_update_invoice_status();
