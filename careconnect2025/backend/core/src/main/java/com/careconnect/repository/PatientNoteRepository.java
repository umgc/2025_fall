package com.careconnect.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.careconnect.model.PatientNote;

@Repository
public interface PatientNoteRepository extends JpaRepository<PatientNote, Long> {

}



