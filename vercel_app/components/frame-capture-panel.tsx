"use client";

import { useEffect, useRef, useState } from "react";

interface FrameCapturePanelProps {
  disabled?: boolean;
  onAddFrame: (file: File) => void;
}

export function FrameCapturePanel({ disabled, onAddFrame }: FrameCapturePanelProps) {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const [enabled, setEnabled] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    return () => {
      streamRef.current?.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    };
  }, []);

  async function enableCamera() {
    try {
      setError(null);
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: { facingMode: "user" },
      });
      streamRef.current?.getTracks().forEach((track) => track.stop());
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
      }
      setEnabled(true);
    } catch {
      setError("Frame capture needs camera permission. Use upload frames if browser access is unavailable.");
    }
  }

  async function captureFrame() {
    if (!videoRef.current) {
      return;
    }
    const canvas = document.createElement("canvas");
    canvas.width = videoRef.current.videoWidth || 1280;
    canvas.height = videoRef.current.videoHeight || 720;
    const context = canvas.getContext("2d");
    if (!context) {
      return;
    }
    context.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height);
    const blob = await new Promise<Blob | null>((resolve) =>
      canvas.toBlob(resolve, "image/jpeg", 0.92),
    );
    if (!blob) {
      return;
    }
    onAddFrame(
      new File([blob], `enrollment-frame-${Date.now()}.jpg`, {
        type: "image/jpeg",
      }),
    );
  }

  return (
    <div className="frame-capture">
      <div className="frame-capture__viewport">
        <video autoPlay className="camera-panel__video" muted playsInline ref={videoRef} />
        {!enabled ? (
          <div className="camera-panel__placeholder">
            <p>Open the browser camera to collect multiple enrollment frames for this person.</p>
          </div>
        ) : null}
      </div>
      <div className="frame-capture__actions">
        <button className="button button--secondary" disabled={disabled} onClick={enableCamera} type="button">
          {enabled ? "Restart Camera" : "Open Camera"}
        </button>
        <button
          className="button button--primary"
          disabled={!enabled || disabled}
          onClick={() => {
            void captureFrame();
          }}
          type="button"
        >
          Capture Frame
        </button>
      </div>
      {error ? <p className="camera-panel__error">{error}</p> : null}
    </div>
  );
}
