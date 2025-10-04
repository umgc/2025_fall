# Rate Limiting Implementation for Patient and Caregiver Profiles

## Overview
This document describes the separate rate limiting implementation for patient and caregiver profiles in the CareConnect application. The rate limiting system now provides role-specific and operation-specific (read vs write) rate limits to ensure fair resource usage and system stability.

## Changes Implemented

### 1. Added Profile-Specific Rate Limits

#### Patient Profile Rate Limits (`/v1/api/patients/`)
- **Base Limit**: 30 requests per minute
- **GET operations**: 30 requests per minute
- **POST/PUT/DELETE operations**: 10 requests per minute (stricter for write operations)
- **Extended Limit**: 200 requests per 15 minutes

#### Caregiver Profile Rate Limits (`/v1/api/caregivers/`)
- **Base Limit**: 40 requests per minute
- **GET operations**: 50 requests per minute (higher to allow managing multiple patients)
- **POST/PUT/DELETE operations**: 15 requests per minute
- **Extended Limit**: 300 requests per 15 minutes

#### Family Member Profile Rate Limits (`/v1/api/family-members/`)
- **Base Limit**: 25 requests per minute
- **GET operations**: 30 requests per minute
- **POST/PUT/DELETE operations**: 5 requests per minute (read-only access)
- **Extended Limit**: 150 requests per 15 minutes

### 2. Role-Specific Rate Limiting Logic

Added new methods in `RateLimitingFilter.java`:

- `extractRoleFromUserId()`: Extracts the role from the user identifier
- `getRoleSpecificRateLimit()`: Returns role-specific and operation-specific rate limits
- `getPatientSpecificLimit()`: Returns patient-specific limits based on HTTP method
- `getCaregiverSpecificLimit()`: Returns caregiver-specific limits based on HTTP method
- `getFamilyMemberSpecificLimit()`: Returns family member-specific limits based on HTTP method

### 3. Enhanced Rate Limit Headers

The rate limiting now includes additional headers in the HTTP response:
- `X-RateLimit-Limit`: The current rate limit for the user's role and operation
- `X-RateLimit-Remaining`: The number of requests remaining in the current window
- `X-RateLimit-Reset`: The time window in seconds
- `X-RateLimit-Role`: The role of the authenticated user (PATIENT, CAREGIVER, FAMILY_MEMBER)

### 4. Cache Management

Added a new method `clearAllRateLimits()` to allow clearing all rate limits from the cache, useful for testing and administrative purposes.

## Benefits

1. **Role-Based Security**: Different user roles have different rate limits based on their typical usage patterns
2. **Operation-Based Limits**: Write operations have stricter limits than read operations to protect data integrity
3. **Fair Resource Allocation**: Caregivers managing multiple patients get higher read limits
4. **System Stability**: Prevents abuse and ensures fair usage across all user types
5. **Transparency**: Users can see their rate limits and remaining requests through HTTP headers

## Testing

All existing tests pass, plus new tests added:
- `testPatientProfileRateLimiting()`: Tests patient profile read operation rate limiting
- `testPatientProfileWriteOperationRateLimiting()`: Tests patient profile write operation rate limiting
- `testCaregiverProfileRateLimiting()`: Tests caregiver profile read operation rate limiting
- `testCaregiverProfileWriteOperationRateLimiting()`: Tests caregiver profile write operation rate limiting
- `testFamilyMemberProfileRateLimiting()`: Tests family member profile rate limiting
- `testRoleSpecificRateLimitHeaders()`: Tests that rate limit headers include role information

## Configuration

The rate limits are configurable through the `RATE_LIMITS` and `EXTENDED_LIMITS` maps in `RateLimitingFilter.java`. To adjust limits, modify the values in these maps:

```java
private static final Map<String, Integer> RATE_LIMITS = Map.of(
    "/v1/api/patients/", 30,
    "/v1/api/caregivers/", 40,
    "/v1/api/family-members/", 25,
    // ... other endpoints
);

private static final Map<String, ExtendedLimitConfig> EXTENDED_LIMITS = Map.of(
    "/v1/api/patients/", new ExtendedLimitConfig(200, 15),
    "/v1/api/caregivers/", new ExtendedLimitConfig(300, 15),
    "/v1/api/family-members/", new ExtendedLimitConfig(150, 15),
    // ... other endpoints
);
```

## API Response Example

When a request is rate limited, the API returns a 429 (Too Many Requests) response with the following format:

```json
{
  "error": "Rate limit exceeded",
  "message": "Rate limit exceeded. Please try again in 60 seconds.",
  "retryAfter": 60
}
```

## Future Enhancements

Potential future improvements:
1. Add configurable rate limits through application properties
2. Implement dynamic rate limiting based on system load
3. Add rate limit statistics endpoint for administrators
4. Implement burst allowance for specific operations
5. Add per-endpoint rate limiting granularity

## Files Modified

1. `backend/core/src/main/java/com/careconnect/security/RateLimitingFilter.java`
   - Added profile-specific rate limits
   - Added role-specific rate limiting logic
   - Enhanced rate limit headers
   - Added cache management methods

2. `backend/core/src/test/java/com/careconnect/security/RateLimitingFilterUnitTest.java`
   - Added new tests for profile-specific rate limiting
   - Added tests for role-specific rate limiting
   - Added cache clearing in test setup

## Migration Notes

This implementation is backward compatible with the existing rate limiting system. No migration steps are required. The new rate limits will automatically apply to the patient and caregiver profile endpoints.

