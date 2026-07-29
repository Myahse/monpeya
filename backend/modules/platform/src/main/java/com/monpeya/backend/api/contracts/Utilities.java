package com.monpeya.backend.api.contracts;

import java.util.List;

public final class Utilities {

	private Utilities() {
	}

	public static boolean notBlank(String value) {
		return value != null && !value.isBlank();
	}

	public static boolean isBlank(String value) {
		return value == null || value.isBlank();
	}

	public static <T> boolean isEmpty(List<T> list) {
		return list == null || list.isEmpty();
	}

	public static <T> boolean isNotEmpty(List<T> list) {
		return !isEmpty(list);
	}

	public static boolean isInteger(String value) {
		if (value == null) {
			return false;
		}
		try {
			Integer.parseInt(value.trim());
			return true;
		} catch (NumberFormatException e) {
			return false;
		}
	}

	public static boolean isString(Integer value) {
		return value != null;
	}
}
