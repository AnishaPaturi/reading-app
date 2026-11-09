package com.readingsanctuary.api.sync.dto;

import java.util.List;

public record SyncPushResponse(
        List<String> accepted,
        List<SyncConflictDto> conflicts,
        List<String> rejected,
        long serverCursor
) {
}
