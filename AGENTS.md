# AGENTS.md

## Project overview

This repository contains the Oracle Backend with Firebase APIs (Fusabase) Flutter SDK. The root package depends on the Dart and web workspace packages in `fusabase_dart/` and `fusabase_web/`.

Public Flutter library entry points are `lib/core.dart`, `lib/auth.dart`, `lib/oracledb.dart`, `lib/storage.dart`, and `lib/app_trust.dart`. Check those APIs and their implementations before documenting behavior or changing a public interface.

## Documentation

- `README.md` contains installation instructions and usage examples.
- `agent_docs/core.md`, `agent_docs/configuration.md`, `agent_docs/auth.md`, `agent_docs/oracledb.md`, `agent_docs/storage.md`, and `agent_docs/app_trust.md` provide implementation context, common API patterns, and platform notes for those areas.
- `agent_docs/api-reference.md` explains how to generate the API reference and where its sources live.
- `doc/core.md`, `doc/auth.md`, `doc/oracledb.md`, `doc/storage.md`, and `doc/app_trust.md` are Dartdoc category descriptions.
- `dartdoc_options.yaml` maps API categories to the Markdown files in `doc/`.
- `doc/header.html` and `doc/footer.html` are templates for generated API reference pages.
- Read `CONTRIBUTING.md` for contribution requirements and `SECURITY.md` for vulnerability reporting.

When a public API or its behavior changes, update the relevant `agent_docs/*.md` and `doc/*.md` pages and any affected README examples. Keep documentation consistent with the public Dart API and implementation.

## Development commands

Run these from the repository root:

```bash
flutter pub get
dart analyze
flutter test
```

Generate the API reference with:

```bash
dart run dartdoc
```

The generated reference is written to `doc/api/`.

## Code conventions

- Follow the lints in `analysis_options.yaml` and format changed Dart files with `dart format`.
- Keep changes focused on the requested behavior and preserve the existing public API patterns.
- Add or update `{@category ...}` annotations and the matching `dartdoc_options.yaml` entry when adding a public library category.
