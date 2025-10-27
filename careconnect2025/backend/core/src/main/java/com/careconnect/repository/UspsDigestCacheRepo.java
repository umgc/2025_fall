package com.careconnect.repository;

import com.careconnect.model.UspsDigestCache;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface UspsDigestCacheRepo extends JpaRepository<UspsDigestCache, Long> {
    Optional<UspsDigestCache> findFirstByUserIdAndExpiresAtAfterOrderByDigestDateDesc(
            String userId, Instant now
    );

    @Query("SELECT c FROM UspsDigestCache c WHERE c.userId = :userId AND " +
           "DATE(c.digestDate) = :date AND c.expiresAt > CURRENT_TIMESTAMP")
    Optional<UspsDigestCache> findByUserIdAndDigestDate(
            @Param("userId") String userId,
            @Param("date") LocalDate date
    );

    List<UspsDigestCache> findAllByUserId(String userId);

    int deleteByUserId(String userId);
}
