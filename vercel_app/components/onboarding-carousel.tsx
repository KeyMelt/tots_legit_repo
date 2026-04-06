"use client";

import { useEffect, useState, type CSSProperties } from "react";

import { PrimaryButton, SecondaryButton } from "@/components/common";

const slides = [
  {
    title: "Precision Identity Redefined",
    body:
      "Experience the next generation of biometric security with fast guest recognition and clear status checks.",
    signalLabel: "Signal strength",
    signalValue: "98.4%",
    matchLabel: "Neural match",
    matchValue: "Ready",
    imageUrl:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuCl3ZjI-6HbuamYj_b0O7t-3dK1ibIs8LOZAh5Rt4n4bipajHR3TQK2MddGuEZRStV25CGQZQKKdSYjKrq6-dlgsaaOsq9CkAa-Nw6tEht-imvbJ6VytcTv3mWCKdyGuSEWOq5gtwqwyUhtoVF8a0EIUNiaTJuS9x3gipidRKZqfsseaxWfZbU3KDfuYgQPaPoYCzkUj5z0QwZVXPc6CGhwHSclHruTs8GvjJxsnVbExIftvDxhDqvVpIaOPYkQBeKK82ZeK2bYVr2g",
    accent: "var(--primary)",
  },
  {
    title: "Capture Every Guest In Seconds",
    body:
      "Use the live camera or upload from the device to verify accepted, rejected, and unknown attendees instantly.",
    signalLabel: "Entry flow",
    signalValue: "Synced",
    matchLabel: "Check-in rate",
    matchValue: "Fast",
    imageUrl:
      "https://images.unsplash.com/photo-1516321497487-e288fb19713f?auto=format&fit=crop&w=900&q=80",
    accent: "var(--primary-strong)",
  },
  {
    title: "Know Who Is On The List",
    body:
      "Review scan history, filter by attendee status, and pull up details whenever the team needs a quick answer.",
    signalLabel: "Event status",
    signalValue: "Live",
    matchLabel: "Guest access",
    matchValue: "Tracked",
    imageUrl:
      "https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=900&q=80",
    accent: "var(--violet)",
  },
];

export function OnboardingCarousel() {
  const [currentIndex, setCurrentIndex] = useState(0);

  useEffect(() => {
    const timer = window.setInterval(() => {
      setCurrentIndex((value) => (value + 1) % slides.length);
    }, 5000);
    return () => window.clearInterval(timer);
  }, []);

  const slide = slides[currentIndex];

  return (
    <div className="hero-card">
      <div className="hero-card__visual" style={{ "--hero-accent": slide.accent } as CSSProperties}>
        <img alt={slide.title} className="hero-card__image" src={slide.imageUrl} />
        <div className="hero-card__metrics">
          <div>
            <span className="eyebrow">{slide.signalLabel}</span>
            <strong>{slide.signalValue}</strong>
          </div>
          <div>
            <span className="eyebrow">{slide.matchLabel}</span>
            <strong>{slide.matchValue}</strong>
          </div>
        </div>
      </div>
      <div className="hero-card__body">
        <div className="hero-card__dots" aria-label="Onboarding steps">
          {slides.map((entry, index) => (
            <button
              aria-label={`Show slide ${index + 1}: ${entry.title}`}
              className={`hero-card__dot ${index === currentIndex ? "hero-card__dot--active" : ""}`}
              key={entry.title}
              onClick={() => setCurrentIndex(index)}
              type="button"
            />
          ))}
        </div>
        <h2>{slide.title}</h2>
        <p>{slide.body}</p>
        <div className="hero-card__actions">
          <PrimaryButton href="/signup">Get Started</PrimaryButton>
          <SecondaryButton href="/login">Existing Account Login</SecondaryButton>
        </div>
      </div>
    </div>
  );
}
