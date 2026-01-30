---
trigger: always_on
---

# 🚫 No-Shortcuts Coding Rules (Strict Mode)

Use these rules **verbatim** in your IDE / AI coding assistant to enforce **complete, production-ready code**.

---

## ❌ Prohibited Practices

- **Do NOT use placeholders**
  - No `TODO`, `FIXME`, `later`, `dummy`, `mock`, `sample`
  - No commented-out incomplete code

- **Do NOT use fallback logic**
  - No “return null for now”
  - No “handle later”
  - No default or fake values unless explicitly requested

- **No pseudo-code**
  - All code must be real, executable code

---

## ✅ Mandatory Requirements

- **Always write FULL implementations**
  - Every function must be fully implemented
  - Every class must be usable as-is
  - No partial or stub logic

- **Production-ready only**
  - Code must compile and run without modification
  - Include all required imports, dependencies, and configurations
  - Follow framework and language best practices

- **Explicit error handling**
  - Handle all expected errors properly
  - Use meaningful error messages and exceptions
  - No silent failures

---

## 🧠 Clarity & Assumptions

- **No assumptions**
  - If anything is unclear, **ask BEFORE coding**
  - Do not invent APIs, fields, or behaviors without clearly stating them

- **Consistent structure**
  - Clean naming conventions
  - Clear separation of concerns
  - Maintainable and readable architecture

---

## 🚀 End-to-End Completeness

If implementing a feature, **ALL of the following must be included**:
- Models
- Services
- Business logic
- Validation
- Integration points

No “example-only” or tutorial code.  
Code must be suitable for real application usage.

---

## 🔍 Mandatory Static Analysis

- **Always run `flutter analyze`**
  - Must be executed **after every prompt execution**
  - Code is considered **incomplete** if `flutter analyze` reports:
    - Errors
    - Warnings
    - Lints
  - All issues **must be fixed**, not ignored or suppressed
  - Do **NOT** use `// ignore`, `// ignore_for_file`, or lint suppression unless explicitly approved

> **Final output is valid only when `flutter analyze` passes with zero issues.**

---

## 📝 Output Rules

- **Explain only AFTER code**
  - First provide the complete code
  - Explanation only if explicitly asked

---

## 🛑 Final Enforcement Rule

> **If you cannot fully implement any part, STOP and ask for clarification instead of guessing.**
