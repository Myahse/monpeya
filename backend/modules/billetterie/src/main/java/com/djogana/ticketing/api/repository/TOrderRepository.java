package com.djogana.ticketing.api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.djogana.ticketing.api.entity.TOrder;

public interface TOrderRepository extends JpaRepository<TOrder, String> {
}
