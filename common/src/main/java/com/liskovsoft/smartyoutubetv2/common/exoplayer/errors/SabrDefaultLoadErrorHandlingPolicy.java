package com.liskovsoft.smartyoutubetv2.common.exoplayer.errors;

import com.liskovsoft.sharedutils.helpers.Helpers;

import java.io.IOException;

public class SabrDefaultLoadErrorHandlingPolicy extends DashDefaultLoadErrorHandlingPolicy {
    @Override
    public long getExclusionDurationMsFor(LoadErrorInfo loadErrorInfo) {
        return super.getExclusionDurationMsFor(loadErrorInfo);
    }

    @Override
    public long getRetryDelayMsFor(LoadErrorInfo loadErrorInfo) {
        if (Helpers.contains(loadErrorInfo.exception.getMessage(), "Wait 5 sec")) {
            return 5_000;
        }

        return super.getRetryDelayMsFor(loadErrorInfo);
    }
}
