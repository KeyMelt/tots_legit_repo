"use client";

import { useEffect, useRef, useState } from "react";

interface CameraPanelProps {
  busy: boolean;
  onCapture: (file: File) => Promise<void>;
}

export function CameraPanel({ busy, onCapture }: CameraPanelProps) {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const [enabled, setEnabled] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [capturing, setCapturing] = useState(false);

  useEffect(() => {
    return () => {
      stopStream(streamRef.current);
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
      stopStream(streamRef.current);
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
      }
      setEnabled(true);
    } catch {
      setError("Camera access was blocked. Upload a photo instead or retry with browser permissions enabled.");
    }
  }

  async function captureFrame() {
    if (!videoRef.current) {
      return;
    }

    setCapturing(true);
    try {
      const canvas = document.createElement("canvas");
      canvas.width = videoRef.current.videoWidth || 1280;
      canvas.height = videoRef.current.videoHeight || 720;
      const context = canvas.getContext("2d");
      if (!context) {
        throw new Error("No canvas context.");
      }
      context.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height);
      const blob = await new Promise<Blob | null>((resolve) =>
        canvas.toBlob(resolve, "image/jpeg", 0.92),
      );
      if (!blob) {
        throw new Error("The browser could not capture a frame.");
      }
      const file = new File([blob], `camera-capture-${Date.now()}.jpg`, {
        type: "image/jpeg",
      });
      await onCapture(file);
    } finally {
      setCapturing(false);
    }
  }

  return (
    <div className="camera-panel">
      <div className="camera-panel__viewport">
        <video autoPlay className="camera-panel__video" muted playsInline ref={videoRef} />
        {!enabled ? (
          <div className="camera-panel__placeholder">
            <p>Enable the browser camera to capture one verification frame at a time.</p>
          </div>
        ) : null}
      </div>
      <div className="camera-panel__actions">
        <button className="button button--secondary" onClick={enableCamera} type="button">
          {enabled ? "Restart Camera" : "Enable Camera"}
        </button>
        <button
          className="button button--primary"
          disabled={!enabled || capturing || busy}
          onClick={() => {
            void captureFrame();
          }}
          type="button"
        >
          {capturing || busy ? "Processing..." : "Capture Scan"}
        </button>
      </div>
      {error ? <p className="camera-panel__error">{error}</p> : null}
    </div>
  );
}

function stopStream(stream: MediaStream | null) {
  stream?.getTracks().forEach((track) => track.stop());
}
