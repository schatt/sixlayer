# SixLayer Framework v8.8.1 Release Documentation

**Release Date**: November 17, 2026  
**Release Type**: Patch  
**Previous Release**: v8.8.0  
**Status**: Prepared (docs); tagging is the `--release` gate

---

## 🎯 Release Summary

v8.8.1 is a **patch** on v8.8.0. It picks up the Dependabot bundler-group bump of the Ruby `json` gem (indirect; development tooling), with no public Swift API changes.

This file does not claim the suite was run for a release until the release script's test gate passes.

---

## 🆕 New in this tag (since v8.8.0)

### Bundler `json` bump (Dependabot) — Issue #698

Updates `json` from 2.17.1.2 to 2.19.9 in the bundler dependency group (`0a8d0ef92`, merged on `next` as `ff0fb43b6`). Closes the v8.8.1 milestone item [Issue #698](https://github.com/schatt/sixlayer/issues/698) (Update bundler).

---

## ⚠️ Migration / consumer notes

No public API changes. Framework consumers on v8.8.0 can take this tag for tooling lockfile currency; behavior of the Swift package is unchanged.

---

## 📚 References

- Previous: [RELEASE_v8.8.0.md](RELEASE_v8.8.0.md)
- Milestone issues: [#698](https://github.com/schatt/sixlayer/issues/698)
- Prep: [#699](https://github.com/schatt/sixlayer/issues/699)
