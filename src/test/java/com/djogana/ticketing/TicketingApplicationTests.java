package com.djogana.ticketing;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(classes = com.djogana.ticketing.api.Application.class)
@ActiveProfiles("test")
class TicketingApplicationTests {

	@Test
	void contextLoads() {
	}

}
