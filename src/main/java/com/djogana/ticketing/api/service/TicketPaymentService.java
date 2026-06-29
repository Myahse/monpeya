package com.djogana.ticketing.api.service;

import java.util.Locale;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import lombok.Getter;

@Service
public class TicketPaymentService {

	private static final Logger log = LoggerFactory.getLogger(TicketPaymentService.class);

	@Value("${ticket.purchase.debit.enabled:false}")
	private boolean debitEnabled;

	public PaymentResult processWalletDebit(String codeClient, java.math.BigDecimal amount, Locale locale) {
		if (!debitEnabled) {
			log.info("ticket.purchase.debit.enabled=false — simulated Peya payment for codeClient={}", codeClient);
			return PaymentResult.simulated();
		}

		// Peya wallet debit via FarfarUtils + W_Comptes (no card / W_CLIENTS_CARTE tables).
		log.warn("Peya debit enabled but FarfarUtils wiring is not configured for ticketing yet");
		return PaymentResult.failed("Peya payment integration not configured");
	}

	@Getter
	public static final class PaymentResult {
		private final boolean success;
		private final String paymentReference;
		private final String referOp;
		private final String errorMessage;

		private PaymentResult(boolean success, String paymentReference, String referOp, String errorMessage) {
			this.success = success;
			this.paymentReference = paymentReference;
			this.referOp = referOp;
			this.errorMessage = errorMessage;
		}

		public static PaymentResult simulated() {
			return new PaymentResult(true, "SIM-" + UUID.randomUUID(), "SIM-REF-OP", null);
		}

		public static PaymentResult failed(String message) {
			return new PaymentResult(false, null, null, message);
		}
	}
}
