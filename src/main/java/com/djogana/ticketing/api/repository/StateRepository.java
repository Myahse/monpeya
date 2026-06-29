package com.djogana.ticketing.api.repository;

import com.djogana.ticketing.api.entity.State;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface StateRepository extends JpaRepository<State, String> {

    @Query("select e from State e where e.node = :node")
    State findByCode(@Param("node") String node);
}

