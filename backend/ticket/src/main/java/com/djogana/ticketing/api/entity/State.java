package com.djogana.ticketing.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.sql.Date;

@Getter
@Setter
@Entity
@Table(name = "STATE")
public class State {

    @Id
    @Column(name = "NODE")
    private String node;

    @Column(name = "DATOPER")
    private Date dateOper;
}

