"use client";

import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";

import { AppMark, InlineMessage, PrimaryButton, SecondaryButton } from "@/components/common";
import { saveDemoSession } from "@/lib/session";

export default function SignUpPage() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!name.trim()) {
      setError("Enter your name.");
      return;
    }
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
      name: name.trim(),
    });
    router.replace("/scan");
  }

  return (
    <main className="auth-page">
      <section className="auth-card">
        <AppMark />
        <div className="auth-card__copy">
          <p className="eyebrow">Operator onboarding</p>
          <h1>Create Your Access</h1>
          <p>Set up a new operator profile for scanning and attendee review.</p>
        </div>
        <form className="auth-form" onSubmit={handleSubmit}>
          <label>
            Full name
            <input onChange={(event) => setName(event.target.value)} type="text" value={name} />
          </label>
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
              autoComplete="new-password"
              onChange={(event) => setPassword(event.target.value)}
              type="password"
              value={password}
            />
          </label>
          {error ? <InlineMessage tone="error">{error}</InlineMessage> : null}
          <PrimaryButton type="submit">Sign Up</PrimaryButton>
          <SecondaryButton href="/login">Already have an account? Login</SecondaryButton>
        </form>
      </section>
    </main>
  );
}
