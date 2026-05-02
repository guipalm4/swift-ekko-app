# Agent Playbook — Ekko

Recipes for operations that recurred across sessions. Agent reads the relevant section
and executes the command directly — no need to rediscover syntax.

---

## Build & Test

### Full test suite (mandatory for DOD)
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

### Fast feedback — one target only
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter EkkoCoreTests
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter EkkoPlatformTests
```

### Build all SPM targets
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```

### Build + run CLI binary
```bash
# Build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build --product EkkoCLI

# Run directly (preferred — swift run + -- passes flags incorrectly)
.build/debug/EkkoCLI --version
.build/debug/EkkoCLI --help
.build/debug/EkkoCLI agent-trigger
```
> ⚠️ Do NOT use `swift run EkkoCLI -- --version` — ArgumentParser does not receive the flags correctly via that form. Run the binary directly from `.build/debug/`.

### Build EkkoApp (Xcode)
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild build -scheme EkkoApp -destination 'platform=macOS' \
  -project /Users/guipalm4/Dev/Projects/Personal/swift/ekko-app/EkkoApp/EkkoApp.xcodeproj \
  2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)"
```

### Verify product/target names in Package.swift
```bash
grep -E "\.library|\.executable|\.target|\.testTarget|\.executableTarget" \
  /Users/guipalm4/Dev/Projects/Personal/swift/ekko-app/Package.swift
```

---

## Naming Audit

### Find all Ekka* naming errors (should be Ekko*)
```bash
grep -rn "Ekka" \
  Sources/ Tests/ Package.swift EkkoApp/ \
  CLAUDE.md .claude/napkin.md .claude/playbook.md \
  .specs/ \
  2>/dev/null \
  | grep -v ".build/" | grep -v "xcuserstate" | grep -v "Binary file"
```
Intentional occurrences (keep): contrast lines like `` `EkkoPlatform` ≠ `EkkaPlatform` `` and historical fix notes.

### Architecture purity check (EkkoCore must have zero results)
```bash
grep -r "import AppKit\|import SwiftUI\|import ServiceManagement" Sources/EkkoCore/
```

---

## File Editing — Unicode-Safe

### When sed fails on files with Unicode (→, ↔, emoji)
Use Python instead of sed for any file containing multi-byte characters (tasks.md, CLAUDE.md, napkin.md):

```python
python3 -c "
path = 'path/to/file.md'
with open(path, 'r') as f:
    content = f.read()
content = content.replace('old string', 'new string')
with open(path, 'w') as f:
    f.write(content)
print('done')
"
```

For bulk replacements across multiple files:
```python
python3 -c "
files = ['file1.md', 'file2.md']
for path in files:
    with open(path, 'r') as f:
        content = f.read()
    new = content.replace('old', 'new')
    if new != content:
        with open(path, 'w') as f:
            f.write(new)
        print(f'fixed: {path}')
"
```

---

## Git Operations

### Stage EkkoApp changes (exclude xcuserdata and IDE state)
```bash
git add \
  EkkoApp/EkkoApp.xcodeproj/project.pbxproj \
  EkkoApp/EkkoApp.xcodeproj/project.xcworkspace/contents.xcworkspacedata \
  EkkoApp/EkkoApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved \
  EkkoApp/EkkoApp/ \
  EkkoApp/EkkoAppTests/ \
  EkkoApp/EkkoAppUITests/
```
> ⚠️ Never use `git add EkkoApp/` — it includes `xcuserdata/` and `.xcuserstate` which are in `.gitignore` but get staged anyway when using recursive add on a new directory.

### Rename SPM test target directory
```bash
# Rename directory (preserves git history)
git mv Tests/OldTargetTests Tests/NewTargetTests

# Then update Package.swift target name and all doc references
# Then run swift test to verify
```

### Stage + commit SPM source changes only
```bash
git add Sources/ Tests/ Package.swift Package.resolved
```

---

## Xcode Project (pbxproj) — Add Local Package Product Dependencies

When a local SPM package is referenced at project level but products are not linked to a target,
add these sections manually. Replace `NEWID_*` with fresh 24-char hex UUIDs.

**Step 1 — Add PBXBuildFile entries** (after `objects = {` or before first section):
```
/* Begin PBXBuildFile section */
    NEWID_BF_CORE /* EkkoCore in Frameworks */ = {isa = PBXBuildFile; productRef = NEWID_DEP_CORE /* EkkoCore */; };
    NEWID_BF_PLAT /* EkkoPlatform in Frameworks */ = {isa = PBXBuildFile; productRef = NEWID_DEP_PLAT /* EkkoPlatform */; };
/* End PBXBuildFile section */
```

**Step 2 — Add XCSwiftPackageProductDependency section** (before XCLocalSwiftPackageReference section):
```
/* Begin XCSwiftPackageProductDependency section */
    NEWID_DEP_CORE /* EkkoCore */ = {
        isa = XCSwiftPackageProductDependency;
        package = <PACKAGE_REF_ID> /* XCLocalSwiftPackageReference "..." */;
        productName = EkkoCore;
    };
    NEWID_DEP_PLAT /* EkkoPlatform */ = {
        isa = XCSwiftPackageProductDependency;
        package = <PACKAGE_REF_ID> /* XCLocalSwiftPackageReference "..." */;
        productName = EkkoPlatform;
    };
/* End XCSwiftPackageProductDependency section */
```

**Step 3 — Update PBXFrameworksBuildPhase `files` for the app target:**
```
files = (
    NEWID_BF_CORE /* EkkoCore in Frameworks */,
    NEWID_BF_PLAT /* EkkoPlatform in Frameworks */,
);
```

**Step 4 — Update PBXNativeTarget `packageProductDependencies`:**
```
packageProductDependencies = (
    NEWID_DEP_CORE /* EkkoCore */,
    NEWID_DEP_PLAT /* EkkoPlatform */,
);
```

**Step 5 — Add locale to knownRegions** (in PBXProject section):
```
knownRegions = (
    en,
    "pt-BR",
    Base,
);
```

> Note: `productName` must match the exact `name:` declared in the SPM `products:` array.
> Verify with: `grep -E "\.library|\.executable" Package.swift`

---

## Localizable.xcstrings — Minimal Template

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "KEY" : {
      "comment" : "Description",
      "localizations" : {
        "en" : {
          "stringUnit" : { "state" : "translated", "value" : "EN value" }
        },
        "pt-BR" : {
          "stringUnit" : { "state" : "translated", "value" : "PT-BR value" }
        }
      }
    }
  },
  "version" : "1.0"
}
```
For `Text("Ekko \(EkkoVersion.current)")` in SwiftUI, the catalog key is `"Ekko %@"`.

---

## tasks.md — Mark Task Complete

When the Edit tool fails (file modified by linter/other), use Python:
```python
python3 -c "
path = '.specs/features/m0-foundation/tasks.md'
with open(path, 'r') as f:
    content = f.read()

# Replace DOD checkboxes
replacements = [
    ('- [ ] Some DOD item', '- [x] Some DOD item'),
]
for old, new in replacements:
    content = content.replace(old, new, 1)  # count=1 to avoid hitting T17 duplicates

with open(path, 'w') as f:
    f.write(content)
print('done')
"
```
> ⚠️ Always use `replace(old, new, 1)` (count=1) for DOD items — some checklist items appear
> in both T14 and T17 (e.g. the xcodebuild gate). Without count=1, both get marked.
