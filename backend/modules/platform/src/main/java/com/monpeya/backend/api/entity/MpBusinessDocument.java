package com.monpeya.backend.api.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "MP_BUSINESS_DOCUMENT")
public class MpBusinessDocument {

	@Id
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "mp_business_doc_seq")
	@SequenceGenerator(name = "mp_business_doc_seq", sequenceName = "MP_BUSINESS_DOC_SEQ", allocationSize = 1)
	@Column(name = "ID")
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "PROFILE_ID", nullable = false)
	private MpServiceProfile profile;

	/** ID_CARD_FRONT | ID_CARD_BACK | BUSINESS_REG | OTHER */
	@Column(name = "DOC_TYPE", nullable = false, length = 40)
	private String docType;

	@Column(name = "FILE_REF", length = 500)
	private String fileRef;

	/** PENDING | ACCEPTED | REJECTED */
	@Column(name = "STATUS", nullable = false, length = 20)
	private String status = "PENDING";

	@Column(name = "REVIEW_NOTE", length = 500)
	private String reviewNote;

	@Column(name = "CREATED_AT", nullable = false)
	private LocalDateTime createdAt = LocalDateTime.now();

	@Column(name = "UPDATED_AT", nullable = false)
	private LocalDateTime updatedAt = LocalDateTime.now();
}
