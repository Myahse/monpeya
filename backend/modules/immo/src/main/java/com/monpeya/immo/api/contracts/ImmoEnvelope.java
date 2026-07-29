package com.monpeya.immo.api.contracts;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class ImmoEnvelope {

    private ImmoEnvelope() {
    }

    public static Map<String, Object> ok(List<Map<String, Object>> items) {
        Map<String, Object> envelope = base(false);
        envelope.put("items", items != null ? items : Collections.emptyList());
        envelope.put("count", items != null ? items.size() : 0);
        return envelope;
    }

    public static Map<String, Object> item(Map<String, Object> item) {
        Map<String, Object> envelope = base(false);
        envelope.put("item", item);
        envelope.put("items", item != null ? List.of(item) : Collections.emptyList());
        envelope.put("count", item != null ? 1 : 0);
        return envelope;
    }

    public static Map<String, Object> error(String message) {
        Map<String, Object> envelope = base(true);
        envelope.put("status", Map.of("message", message));
        return envelope;
    }

    private static Map<String, Object> base(boolean hasError) {
        Map<String, Object> envelope = new LinkedHashMap<>();
        envelope.put("hasError", hasError);
        if (!hasError) {
            envelope.put("status", Map.of("message", "OK"));
        }
        return envelope;
    }
}
