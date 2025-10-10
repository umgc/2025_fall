package com.careconnect.evv;

import com.careconnect.service.EvvSubmissionService;
import org.junit.jupiter.api.Test;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;

class StateSpecificIntegrationSelectionTest {
    @Test
    void destination_switchCoversAllStates() {
        var svc = new EvvSubmissionService(List.of(), null, null, null);
        assertThat(svc.destinationFor("MD")).isEqualTo("maryland-info-only");
        assertThat(svc.destinationFor("DC")).isEqualTo("dc-sandata");
        assertThat(svc.destinationFor("VA")).isEqualTo("virginia-mco");
    }
}
