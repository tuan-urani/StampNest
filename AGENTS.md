# AGENTS.md — stamp_v2

## Local Pack
Instructions installed at `.codex`. Read the relevant SKILL.md or rule file before writing code.

## Skill Triggers
Read the matching SKILL.md **before** writing code when a task maps to that skill.

- **dart-best-practices** — General purity standards for Dart development.
  `.codex/skills/dart-best-practices/SKILL.md`
- **dart-language-patterns** — Modern Dart standards (3.x+) including null safety and patterns.
  `.codex/skills/dart-language-patterns/SKILL.md`
- **dart-model-reuse** — Guides model reuse/composition and safe extension. Invoke when adding/updating UI/domain models or preventing duplicate screen-specific models.
  `.codex/skills/dart-model-reuse/SKILL.md`
- **dart-tooling-ci** — Standards for analysis, linting, formatting, and automation.
  `.codex/skills/dart-tooling-ci/SKILL.md`
- **flutter-assets-management** — Standards for asset naming, organization, and synchronization with design tools.
  `.codex/skills/flutter-assets-management/SKILL.md`
- **flutter-bloc-state-management** — Standards for predictable state management using flutter_bloc and equatable. Invoke when implementing BLoCs/Cubits, Events, States, or refactoring page widgets into components.
  `.codex/skills/flutter-bloc-state-management/SKILL.md`
- **flutter-dependency-injection-injectable** — Standards for dependency injection using GetX Bindings and Service Locator.
  `.codex/skills/flutter-dependency-injection-injectable/SKILL.md`
- **flutter-error-handling** — Typed error handling with Result<T> and Failure models using Dio. Invoke when implementing repository error flow, mapping API errors, or handling exceptions in BLoC.
  `.codex/skills/flutter-error-handling/SKILL.md`
- **flutter-navigation-manager** — Routing strategy management (GetX is the Project Standard).
  `.codex/skills/flutter-navigation-manager/SKILL.md`
- **flutter-standard-lib-src-architecture** — Standard folder structure and component extraction rules for Flutter apps under lib/src/. Invoke when scaffolding a new page, feature module, or shared widget.
  `.codex/skills/flutter-standard-lib-src-architecture/SKILL.md`
- **flutter-standard-lib-src-architecture-dependency-rules** — Dependency flow and separation of concerns for the project (UI -> BLoC -> Repository).
  `.codex/skills/flutter-standard-lib-src-architecture-dependency-rules/SKILL.md`
- **flutter-ui-widgets** — Principles for maintainable UI components and project-specific widget standards.
  `.codex/skills/flutter-ui-widgets/SKILL.md`
- **getx-localization-standard** — Standards for GetX-based multi-language (locale_key + lang_*.dart). Invoke when generating a new page/feature or adding any user-facing text.
  `.codex/skills/getx-localization-standard/SKILL.md`
- **ui-documentation-workflow** — Generates and maintains spec/ui-workflow.md for UI flows. Invoke when creating/modifying features or when asked to update documentation.
  `.codex/skills/ui-documentation-workflow/SKILL.md`

## Rule Triggers
Apply the matching rule file **before** making changes.

- **ci-cd-pr.md** — Commit/push/PR gate after completing any UI or API feature.
  `.codex/rules/ci-cd-pr.md`
- **integration-api.md** — API integration: endpoint mapping, models, repository, bloc wiring.
  `.codex/rules/integration-api.md`
- **ui-refactor-convert.md** — Post-convert/Figma output cleanup: rename, decompose, tokenize, localize.
  `.codex/rules/ui-refactor-convert.md`
- **ui.md** — UI creation, widget composition, tokens, localization, state coverage, PR checklist.
  `.codex/rules/ui.md`
- **unit-test.md** — Unit test authoring standards.
  `.codex/rules/unit-test.md`
- **widget-test.md** — Widget test authoring standards.
  `.codex/rules/widget-test.md`

## Quality Gate (Required Before Commit)
```bash
dart format lib test \
  && dart fix lib --apply --code=unused_import,duplicate_import,prefer_single_quotes \
  && dart fix test --apply --code=unused_import,duplicate_import,prefer_single_quotes
```

## Commit / Push / PR Gate
After completing any UI or API feature, ask the user in strict order:
1. `Do you want me to commit now? (yes/no)`
2. `Do you want me to push now? (yes/no)`
3. `Do you want me to create PR now? (yes/no)`
Execute only the steps confirmed with `yes`. Stop and report status on `no`.

## Paths
- Project root: `/Users/uranidev/Documents/stamp_v2`
- Local pack:   `.codex`
