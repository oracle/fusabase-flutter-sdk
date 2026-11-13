# API Reference

Use the generated Dartdoc site for a fuller view of the public Flutter SDK API.

## Generate the Docs

From the repository root:

```bash
sh tool/generate_api_docs.sh
```

The generated site is written to `doc/api/`. The generation script also copies
the Fusabase logo into the generated site's `assets/` directory.

The documented public entry points are:

- `package:fusabase/core.dart`
- `package:fusabase/auth.dart`
- `package:fusabase/oracledb.dart`
- `package:fusabase/storage.dart`
- `package:fusabase/app_trust.dart`

## Source Layout

- `lib/` contains the public libraries and their implementations.
- `doc/*.md` supplies the category descriptions consumed by Dartdoc.
- `doc/header.html` and `doc/footer.html` supply the generated pages' header and footer.
- `dartdoc_options.yaml` maps `{@category ...}` annotations to the category descriptions.

Update the Dartdoc source comments and the relevant `doc/*.md` category description when public API documentation changes, then regenerate the site to review the output.

## Useful Local Source Anchors

- `lib/core.dart`
- `lib/auth.dart`
- `lib/oracledb.dart`
- `lib/storage.dart`
- `lib/app_trust.dart`
- `dartdoc_options.yaml`
