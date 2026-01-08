package com.liskovsoft.smartyoutubetv2.common.exoplayer.other;

import android.content.Context;
import android.os.Build;
import android.os.Handler;
import androidx.annotation.Nullable;
import androidx.media3.common.C;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.DefaultRenderersFactory;
import androidx.media3.exoplayer.ExoPlayer.Builder;
import androidx.media3.exoplayer.SeekParameters;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.audio.AudioAttributes;
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager;
import androidx.media3.exoplayer.drm.DrmSessionManager;
import androidx.media3.exoplayer.drm.ExoMediaDrm.KeyRequest;
import androidx.media3.exoplayer.drm.ExoMediaDrm.ProvisionRequest;
import androidx.media3.exoplayer.drm.ExoMediaDrm;
import androidx.media3.exoplayer.drm.MediaDrmCallback;
import androidx.media3.exoplayer.drm.UnsupportedDrmException;
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector;
import androidx.media3.datasource.BandwidthMeter;
import androidx.media3.datasource.TransferListener;
import com.liskovsoft.sharedutils.helpers.Helpers;
import com.liskovsoft.smartyoutubetv2.common.prefs.PlayerData;
import com.liskovsoft.smartyoutubetv2.common.prefs.PlayerTweaksData;

import java.util.UUID;

public class ExoPlayerInitializer {
    private final int mMaxBufferBytes;
    private final PlayerData mPlayerData;
    private final PlayerTweaksData mPlayerTweaksData;
    private static AudioAttributes sAudioAttributes;

    public ExoPlayerInitializer(Context context) {
        mPlayerData = PlayerData.instance(context);
        mPlayerTweaksData = PlayerTweaksData.instance(context);

        // Optimizing RAM allocation for high-speed connections (300mbps+)
        // Use deviceRam / 10 for better 4K/8K buffering.
        long deviceRam = Helpers.getDeviceRam(context);
        long calculatedBuffer = deviceRam / 10;

        // Safety check for 32-bit (ARMv7a) devices which have limited heap per process.
        boolean is64Bit = Build.VERSION.SDK_INT >= 23 && android.os.Process.is64Bit();
        int maxSafeBuffer = is64Bit ? 500_000_000 : 200_000_000;

        mMaxBufferBytes = deviceRam <= 0 ? 196_000_000 : (int) Math.min(calculatedBuffer, maxSafeBuffer);
    }

    public ExoPlayer createPlayer(Context context, DefaultRenderersFactory renderersFactory,
            DefaultTrackSelector trackSelector) {
        DefaultLoadControl loadControl = createLoadControl();

        // HDR fix?
        // trackSelector.setParameters(trackSelector.buildUponParameters().setTunnelingAudioSessionId(C.generateAudioSessionIdV21(context)));

        // Old initializer
        ExoPlayer player = ExoPlayer.Builder.newSimpleInstance(context, renderersFactory, trackSelector,
                loadControl);

        // New initializer
        // ExoPlayer player = ExoPlayer.Builder.newSimpleInstance(
        // context, renderersFactory, trackSelector, loadControl,
        // null, new DummyBandwidthMeter(), new AnalyticsCollector.Factory(),
        // Util.getLooper()
        // );

        // enableAudioFocus(player);

        // Lead to numbered errors
        // player.setRepeatMode(Player.REPEAT_MODE_ONE);

        // Fix still image while audio is playing (happens after format change or exit
        // from sleep)
        // player.setPlayWhenReady(true);

        applyPlaybackFixes(player);

        setupAudioFocus(player);

        setupVolumeBoost(player);

        return player;
    }

    private static AudioAttributes getAudioAttributes() {
        if (sAudioAttributes == null) {
            sAudioAttributes = new AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.CONTENT_TYPE_MOVIE)
                    .build();
        }

        return sAudioAttributes;
    }

    /**
     * Increase player's min/max buffer size to 60 secs
     * 
     * @return load control
     */
    private DefaultLoadControl createLoadControl() {
        DefaultLoadControl.Builder baseBuilder = new DefaultLoadControl.Builder();

        // Default values
        // DefaultLoadControl.DEFAULT_MIN_BUFFER_MS // 15_000
        // DefaultLoadControl.DEFAULT_MAX_BUFFER_MS // 50_000
        // DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_MS // 2_500
        // DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS // 5_000

        // Default values
        int minBufferMs = 15_000;
        int maxBufferMs = 50_000;
        int bufferForPlaybackMs = 1_000; // Snappy startup
        int bufferForPlaybackAfterRebufferMs = 2_000;

        switch (mPlayerData.getVideoBufferType()) {
            case PlayerData.BUFFER_HIGHEST:
                minBufferMs = 120_000; // 2 minutes
                maxBufferMs = 300_000; // 5 minutes
                baseBuilder.setTargetBufferBytes(mMaxBufferBytes);
                baseBuilder.setBackBuffer(60_000, true); // 1 minute of instant seek-back
                break;
            case PlayerData.BUFFER_HIGH:
                minBufferMs = 30_000;
                maxBufferMs = 60_000;
                baseBuilder.setBackBuffer(15_000, true);
                break;
            case PlayerData.BUFFER_MEDIUM:
                minBufferMs = 15_000;
                maxBufferMs = 50_000;
                baseBuilder.setBackBuffer(10_000, true); // Allow 10s of instant seek-back
                break;
            case PlayerData.BUFFER_LOW:
                minBufferMs = 5_000;
                maxBufferMs = 15_000;
                bufferForPlaybackMs = 500; // Almost instant for low-latency/low-res
                bufferForPlaybackAfterRebufferMs = 1_000;
                break;
        }

        baseBuilder
                .setBufferDurationsMs(minBufferMs, maxBufferMs, bufferForPlaybackMs, bufferForPlaybackAfterRebufferMs);

        return baseBuilder.createDefaultLoadControl();
    }

    private void setupVolumeBoost(ExoPlayer player) {
        // 5.1 audio cannot be boosted (format isn't supported error)
        // also, other 2.0 tracks in 5.1 group is already too loud. so cancel them too.
        float volume = mPlayerTweaksData.isPlayerAutoVolumeEnabled() ? 2.0f : mPlayerData.getPlayerVolume();
        if (volume > 1f && Build.VERSION.SDK_INT >= 19) {
            VolumeBooster mVolumeBooster = new VolumeBooster(true, volume, player);
            player.addAudioListener(mVolumeBooster);
        }
    }

    /**
     * Manage audio focus. E.g. use Spotify when audio is disabled.
     */
    private void setupAudioFocus(ExoPlayer player) {
        if (player != null && mPlayerTweaksData.isAudioFocusEnabled()) {
            try {
                player.setAudioAttributes(getAudioAttributes(), true);
            } catch (SecurityException e) { // uid 10390 not allowed to perform TAKE_AUDIO_FOCUS
                e.printStackTrace();
            }
        }
    }

    private void applyPlaybackFixes(ExoPlayer player) {
        // Try to fix decoder error on Nvidia Shield 2019.
        // Init resources as early as possible.
        // player.setForegroundMode(true);
        // NOTE: Avoid using seekParameters. ContentBlock hangs because of constant
        // skipping to the segment start.
        // ContentBlock hangs on the last segment:
        // https://www.youtube.com/watch?v=pYymRbfjKv8

        // Fix seeking on TextureView (some devices only)
        if (mPlayerTweaksData.isTextureViewEnabled()) {
            // Also, live stream (dash) seeking fix
            player.setSeekParameters(SeekParameters.CLOSEST_SYNC);
        }
    }

    private DrmSessionManager<ExoMediaDrm> createDrmManager() {
        try {
            return DefaultDrmSessionManager.newWidevineInstance(new MediaDrmCallback() {
                @Override
                public byte[] executeProvisionRequest(UUID uuid, ProvisionRequest request) {
                    return new byte[0];
                }

                @Override
                public byte[] executeKeyRequest(UUID uuid, KeyRequest request) {
                    return new byte[0];
                }
            }, null);
        } catch (UnsupportedDrmException e) {
            e.printStackTrace();
        }

        return null;
    }

    private static final class DummyBandwidthMeter implements BandwidthMeter {
        @Override
        public long getBitrateEstimate() {
            return 0;
        }

        @Nullable
        @Override
        public TransferListener getTransferListener() {
            return null;
        }

        @Override
        public void addEventListener(Handler eventHandler, EventListener eventListener) {
            // Do nothing.
        }

        @Override
        public void removeEventListener(EventListener eventListener) {
            // Do nothing.
        }
    }
}
