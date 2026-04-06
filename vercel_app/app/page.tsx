"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

import { AppMark } from "@/components/common";
import { OnboardingCarousel } from "@/components/onboarding-carousel";
import { getDemoSession } from "@/lib/session";

export default function HomePage() {
  const router = useRouter();
  const [showOnboarding, setShowOnboarding] = useState(false);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      const session = getDemoSession();
      if (session) {
        router.replace("/scan");
        return;
      }
      setShowOnboarding(true);
    }, 1200);

    return () => window.clearTimeout(timer);
  }, [router]);

  if (!showOnboarding) {
    return (
      <main className="splash-screen">
        <div className="splash-screen__pulse" />
        <AppMark />
        <p>Loading biometric scan console…</p>
      </main>
    );
  }

  return (
    <main className="landing-page">
      <section className="landing-page__content">
        <AppMark />
        <OnboardingCarousel />
      </section>
    </main>
  );
}
