"use client";

import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";

import { AppMark, InlineMessage, PrimaryButton, SecondaryButton } from "@/components/common";
import { saveDemoSession } from "@/lib/session";
import { buildOperatorName } from "@/lib/utils";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!email.includes("@")) {
      setError("Enter a valid email address.");
      return;
    }
    if (password.length < 6) {
      setError("Password must be at least 6 characters.");
      return;
    }

    saveDemoSession({
      email,
      name: buildOperatorName(email),
    });
    router.replace("/scan");
  }

  return (
    <main className="auth-page">
      <section className="auth-card">
        <AppMark />
        <div className="auth-card__copy">
          <p className="eyebrow">Operator access</p>
          <h1>Welcome Back</h1>
          <p>Sign in to continue checking attendee status in real time.</p>
        </div>
        <form className="auth-form" onSubmit={handleSubmit}>
          <label>
            Email
            <input
              autoComplete="email"
              onChange={(event) => setEmail(event.target.value)}
              type="email"
              value={email}
            />
          </label>
          <label>
            Password
            <input
              autoComplete="current-password"
              onChange={(event) => setPassword(event.target.value)}
              type="password"
              value={password}
            />
          </label>
          {error ? <InlineMessage tone="error">{error}</InlineMessage> : null}
          <PrimaryButton type="submit">Login</PrimaryButton>
          <SecondaryButton href="/signup">Need an account? Sign up</SecondaryButton>
        </form>
      </section>
    </main>
  );
}
