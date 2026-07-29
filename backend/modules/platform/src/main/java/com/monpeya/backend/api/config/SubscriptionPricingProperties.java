package com.monpeya.backend.api.config;

import java.math.BigDecimal;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Monpeya access subscription prices from .env / application.properties.
 * Not ticketing product prices.
 */
@Component
@ConfigurationProperties(prefix = "monpeya.subscription")
public class SubscriptionPricingProperties {

	private String currency = "XOF";
	private final PlanPrice client = new PlanPrice();
	private final PlanPrice business = new PlanPrice();

	public String getCurrency() {
		return currency;
	}

	public void setCurrency(String currency) {
		this.currency = currency;
	}

	public PlanPrice getClient() {
		return client;
	}

	public PlanPrice getBusiness() {
		return business;
	}

	public BigDecimal priceForRole(String role) {
		if ("BUSINESS".equalsIgnoreCase(role)) {
			return business.getPrice();
		}
		return client.getPrice();
	}

	public PlanPrice planForRole(String role) {
		if ("BUSINESS".equalsIgnoreCase(role)) {
			return business;
		}
		return client;
	}

	public static class PlanPrice {
		private String code = "CLIENT_ACCESS";
		private String name = "Acces client";
		private String description = "Monpeya client access";
		private BigDecimal price = BigDecimal.valueOf(1000);

		public String getCode() {
			return code;
		}

		public void setCode(String code) {
			this.code = code;
		}

		public String getName() {
			return name;
		}

		public void setName(String name) {
			this.name = name;
		}

		public String getDescription() {
			return description;
		}

		public void setDescription(String description) {
			this.description = description;
		}

		public BigDecimal getPrice() {
			return price;
		}

		public void setPrice(BigDecimal price) {
			this.price = price != null ? price : BigDecimal.ZERO;
		}
	}
}
