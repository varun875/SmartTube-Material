package com.liskovsoft.smartyoutubetv2.tv.ui.playback.other;

import android.os.Bundle;
import android.os.ResultReceiver;
import androidx.annotation.Nullable;
import androidx.media3.exoplayer.ControlDispatcher;
import androidx.media3.common.Player;
import androidx.media3.session.MediaSessionConnector.QueueNavigator;

public class BackboneQueueNavigator implements QueueNavigator {
    @Override
    public long getSupportedQueueNavigatorActions(Player player) {
        return 0;
    }

    @Override
    public void onTimelineChanged(Player player) {

    }

    @Override
    public void onCurrentWindowIndexChanged(Player player) {

    }

    @Override
    public long getActiveQueueItemId(@Nullable Player player) {
        return 0;
    }

    @Override
    public void onSkipToPrevious(Player player, ControlDispatcher controlDispatcher) {

    }

    @Override
    public void onSkipToQueueItem(Player player, ControlDispatcher controlDispatcher, long id) {

    }

    @Override
    public void onSkipToNext(Player player, ControlDispatcher controlDispatcher) {

    }

    @Override
    public boolean onCommand(Player player, ControlDispatcher controlDispatcher, String command, Bundle extras, ResultReceiver cb) {
        return false;
    }
}
