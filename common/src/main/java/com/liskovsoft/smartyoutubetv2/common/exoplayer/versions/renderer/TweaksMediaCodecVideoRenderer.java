package com.liskovsoft.smartyoutubetv2.common.exoplayer.versions.renderer;

import android.annotation.TargetApi;
import android.content.Context;
import android.media.MediaCodec;
import android.os.Handler;
import androidx.annotation.Nullable;
import androidx.media3.common.Format;
import androidx.media3.exoplayer.mediacodec.MediaCodecAdapter;
import androidx.media3.exoplayer.mediacodec.MediaCodecInfo;
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector;
import androidx.media3.exoplayer.video.VideoRendererEventListener;
import com.liskovsoft.sharedutils.mylogger.Log;

public class TweaksMediaCodecVideoRenderer extends DebugInfoMediaCodecVideoRenderer {
    private static final String TAG = TweaksMediaCodecVideoRenderer.class.getSimpleName();
    private boolean mIsFrameDropFixEnabled;
    private boolean mIsFrameDropSonyFixEnabled;
    private boolean mIsAmlogicFixEnabled;

    // Media3 constructor
    public TweaksMediaCodecVideoRenderer(Context context, MediaCodecSelector mediaCodecSelector,
            long allowedJoiningTimeMs,
            boolean enableDecoderFallback, @Nullable Handler eventHandler,
            @Nullable VideoRendererEventListener eventListener, int maxDroppedFramesToNotify) {
        super(context, mediaCodecSelector, allowedJoiningTimeMs, enableDecoderFallback, eventHandler, eventListener,
                maxDroppedFramesToNotify);
    }

    // Exo 2.12, 2.13
    // public TweaksMediaCodecVideoRenderer(Context context, MediaCodecSelector
    // mediaCodecSelector, long allowedJoiningTimeMs,
    // boolean enableDecoderFallback, @Nullable Handler eventHandler,
    // @Nullable VideoRendererEventListener eventListener, int
    // maxDroppedFramesToNotify) {
    // super(context, mediaCodecSelector, allowedJoiningTimeMs,
    // enableDecoderFallback, eventHandler, eventListener,
    // maxDroppedFramesToNotify);
    // }

    @Override
    protected void renderOutputBufferV21(
            MediaCodecAdapter codec, int index, long presentationTimeUs, long releaseTimeNs) {
        // Fix frame drops on SurfaceView
        // https://github.com/google/ExoPlayer/issues/6348
        // https://developer.android.com/reference/android/media/MediaCodec#releaseOutputBuffer(int,%20long)
        super.renderOutputBufferV21(codec, index, presentationTimeUs, mIsFrameDropFixEnabled ? 0 : releaseTimeNs);
    }

    // EXO: 2.13
    // @TargetApi(21)
    // protected void renderOutputBufferV21(
    // MediaCodecAdapter codec, int index, long presentationTimeUs, long
    // releaseTimeNs) {
    // // Fix frame drops on SurfaceView
    // // https://github.com/google/ExoPlayer/issues/6348
    // //
    // https://developer.android.com/reference/android/media/MediaCodec#releaseOutputBuffer(int,%20long)
    // super.renderOutputBufferV21(codec, index, presentationTimeUs, 0);
    // }

    @Override
    protected CodecMaxValues getCodecMaxValues(
            MediaCodecInfo codecInfo, Format format, Format[] streamFormats) {
        CodecMaxValues maxValues = super.getCodecMaxValues(codecInfo, format, streamFormats);

        if (mIsAmlogicFixEnabled) {
            if (maxValues.width < 1920 || maxValues.height < 1089) {
                Log.d(TAG, "Applying Amlogic fix...");
                return new CodecMaxValues(
                        Math.max(maxValues.width, 1920),
                        Math.max(maxValues.height, 1089),
                        maxValues.inputSize);
            }
        }

        return maxValues;
    }

    /**
     * Frame drop fixes on Sony Bravia<br/>
     * https://github.com/google/ExoPlayer/issues/6348#issuecomment-718986083
     */
    @Override
    protected boolean shouldDropOutputBuffer(long earlyUs, long elapsedRealtimeUs, boolean isLastBuffer) {
        if (mIsFrameDropSonyFixEnabled) {
            return earlyUs < -1000000;
        }

        return super.shouldDropOutputBuffer(earlyUs, elapsedRealtimeUs, isLastBuffer);
    }

    /**
     * Frame drop fixes on Sony Bravia<br/>
     * https://github.com/google/ExoPlayer/issues/6348#issuecomment-718986083
     */
    // @Override
    // protected boolean shouldDropBuffersVeryLate(long earlyUs, long
    // elapsedRealtimeUs, boolean isLastBuffer) {
    // if (mIsFrameDropSonyFixEnabled) {
    // return earlyUs < -1500000;
    // }
    //
    // return super.shouldDropBuffersVeryLate(earlyUs, elapsedRealtimeUs,
    // isLastBuffer);
    // }

    public void enableFrameDropFix(boolean enabled) {
        mIsFrameDropFixEnabled = enabled;
    }

    public void enableFrameDropSonyFix(boolean enabled) {
        mIsFrameDropSonyFixEnabled = enabled;
    }

    public void enableAmlogicFix(boolean enabled) {
        mIsAmlogicFixEnabled = enabled;
    }
}
