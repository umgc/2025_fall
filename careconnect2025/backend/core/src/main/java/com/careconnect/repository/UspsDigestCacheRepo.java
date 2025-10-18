package com.careconnect.repository;

import com.careconnect.model.UspsDigestCache;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.Optional;

public interface UspsDigestCacheRepo extends JpaRepository<UspsDigestCache, Long> {
    Optional<UspsDigestCache> findFirstByUserIdAndExpiresAtAfterOrderByDigestDateDesc(
            String userId, Instant now
    );
}
