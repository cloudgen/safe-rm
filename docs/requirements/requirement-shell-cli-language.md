**file**: docs/requirements/requirement-shell-cli-language.md  
**Status**: Active (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-cli-language`  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the project Single Source of Truth for the **menu language** of safe-rm.

Front row **5** opens a language board. The saved choice is the menu copy for later runs of this login. The default is English, so a missing file keeps the English menu words.

**Scope:** Which codes exist, where the choice is stored, which screens follow `APP_LANG`, and which screens stay English.  
**Out of scope:** Which paths `rm` refuses (`requirement-domain-safe-rm.md`). The numbering of **1**, **8**, **9**, **11**, and **82–87** (`requirement-shell-cli-default-interaction.md`). Cache tier order (`requirement-shell-cli-storage.md`). Operational remove sentences, JSON keys, and the `version` one-liner.

### 1.1 Human-facing

**In one sentence:** On the front board, **5** chooses the language of this menu. The next run of `safe-rm` on a terminal uses that language.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | A person at the front board | `safe-rm` then `5` then `52` |
| The other role | A script that never opens the menu | `safe-rm rm --dry-run <path>` stays English |
| Not this file | Which directories the guard refuses | `requirement-domain-safe-rm.md` |

| Includes | Excludes |
|----------|----------|
| Front **5**, rows **51–63**, the leaf `${HOME}/.local/${APP_NAME}/language` | Rows **50** and **64–69** (reserved, not printed) |
| Menu boards, Choice / Path / Back / Exit, help headings, about title and cache labels | Operational `rm` text, JSON about, `version` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Open the language board | Thirteen languages, then Back | `5` |
| Keep Simplified Chinese | The next front board is Simplified Chinese | `52` |
| Step back | The file is not written | `0` |

---

## 2. Core Rules (Mandatory)

### 2.1 Codes

Block **50–69** holds at most 20 languages. **50** and **64–69** are reserved and **MUST NOT** be printed. Front **6** is not a row. Row **5** is shown on every host, including Termux, Git Bash, and Windows cmd.

Speaker order after English, then Simplified Chinese, then Traditional Chinese:

| Row | Code | Short name |
|-----|------|------------|
| **51** | `en` | English |
| **52** | `zh-Hans` | 简体中文 |
| **53** | `zh-Hant` | 繁體中文 |
| **54** | `es` | Español |
| **55** | `ar` | العربية |
| **56** | `fr` | Français |
| **57** | `pt` | Português |
| **58** | `ru` | Русский |
| **59** | `de` | Deutsch |
| **60** | `ja` | 日本語 |
| **61** | `ko` | 한국어 |
| **62** | `nl` | Nederlands |
| **63** | `el` | Ελληνικά |

Those short names are the same in every language. `language` is not an argv verb. A typed alias opens the same row (`english` / `en`, `simplified-chinese` / `zh-Hans` / `简体中文`, and the same shape for the other twelve).

### 2.2 Storage

1. The leaf is `${HOME}/.local/${APP_NAME}/language`. One line. Mode **0600**. It is not in the cache folder.  
2. `app_lang_load` runs **once**, at the start of `app_main`, after persistence is resolved. It **MUST NOT** run again in that process. A later call would let the environment cover a choice just saved.  
3. A missing file, an empty first line, or an unrecognized first line stays English and **MUST NOT** be rewritten.  
4. `SRM_LANG` wins when it is one of the thirteen codes. It does not write the file. The next run without `SRM_LANG` uses the file again.  
5. `app_lang_save` writes only after a successful pick, mode **0600**, then sets `APP_LANG`.  
6. **0**, an empty line, or EOF on the language board is Back and does not write the file.  
7. **50**, **64**, and **69** warn, reprint the board, and do not write the file. The English warn is `Unknown menu choice '50'`. That sentence is not the front-board `Not a menu choice`.

### 2.3 What follows APP_LANG

The front board, the remove-guard board, the path board, the self-management board, and the language board. The prompts Choice, Path, Back, and Exit. Unknown-choice warnings. The human help headings `Usage:`, `Self-Management (Type 0 - any user):`, `Each command is also a switch:`, `Remove guard:`, `Global Options:`, `Environment:`, and the `menu` help sentence. The human about title and the cache, persistence, and useful-commands labels.

English bytes that existing tests match **MUST** stay:

| Surface | English |
|---------|---------|
| Choice | `Choice: ` |
| Path | `Path: ` |
| Current path | `Current path:` |
| custom-path explain | `type a path` |
| Empty path | starts `No path was given` |
| Front unknown | `Not a menu choice '3'` |
| Exit | `9. Exit` |
| Back | `0. Back` |
| Remove-guard explain | `check a path and remove it only when it is allowed` |
| Self-management explain | `this CLI install, version, update, uninstall` |
| Help heading | `Usage:` |
| About title | `About / Diagnostics` |
| Cache label | `Cache folder used:` |

Category shorts are translated. Leaf shorts stay the English verbs `rm`, `version`, `about`, `version-check`, `self-update`, `self-uninstall`, `self-install`, and `custom-path`.

Exit and Back are whole lines (`9. 离开`, `0. 返回`), printed with `out_plain`. They are not `out_menu_choice` rows. The front board accepts the translated category shorts and the translated Exit word. A submenu accepts the translated Back word. An empty line on the front board is Exit. An empty line on a submenu is Back.

The English help `menu` sentence **MUST** contain `5 language`, `52 Simplified Chinese`, and `60 Japanese`.

### 2.4 What stays English

The long help body after each heading. The about paragraph that explains the remove guard. Operational `rm` output. JSON about keys and values. The argv `version` one-liner.

### 2.5 Worked samples

Version token **1.0.20**. English front board:

```text
[INFO] **safe-rm**(*1.0.20*) — Guarded rm that refuses login homes and system directories
1. **remove-guard**: *check a path and remove it only when it is allowed*
5. **language**: *display language for this menu*
8. **self-management**: *this CLI install, version, update, uninstall*
9. Exit
Choice:
```

After **52**, the saved line is `菜单语言是简体中文` and the next front board uses `删除防护`. The first paint of that same run is still English. A later run that only leaves shows `删除防护` and does not show `remove-guard`.

Japanese help heading: `使い方:`. Japanese about title: `概要 / 診断`. Japanese cache label: `使用中のキャッシュフォルダ:`. Korean help heading: `사용법:`. Korean about title: `개요 / 진단`. Korean cache label: `사용 중인 캐시 폴더:`.

### 2.6 Functions

| Function | Role |
|----------|------|
| `app_lang_load` | One read at `app_main` start. Sets `APP_LANG` |
| `app_lang_save` | Writes the leaf after a successful pick |
| `app_menu_text` | Pure data. Prints one string. No input builtin. A missing key prints the key. Safe inside `$(…)` |
| `app_lang_front_kind` | Prints `exit`, `remove`, `language`, `self`, or `other`. No input builtin |
| `app_lang_is_back` | Status 0 when the token is Back |
| `app_cmd_menu_language` | The language board. The choice is read in the current shell |

`app_menu_text` **MUST NOT** contain the four letters `r`, `e`, `a`, `d` in a row, so a comment inside that function cannot name the input builtin. `app_cmd_menu_language` reads in the current shell and **MUST NOT** be captured with `$()`.

### 2.7 Under command line for normal user only

Row **5** is on the front board for Termux, Git Bash, and Windows cmd. Choosing a language does not call `sudo` and does not change the remove guard.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** An unrecognized file stays English and is not rewritten.  
- **Intentional:** One leaf, thirteen codes, English by default.  
- **Anti-fragile:** A failed save warns and does not pretend the choice was stored.  
- **Over-protect:** Reserved numbers stay unprinted. Operational remove text stays English.

---

## 4. Protection Rule (Sacred)

**Future assistants MUST NOT**:

1. Call `app_lang_load` again after a menu pick in the same process.  
2. Rewrite a missing, empty, or unrecognized language file into `en`.  
3. Write the file when `SRM_LANG` is set, or when the board goes Back.  
4. Print **50** or **64–69**, or make front **6** a row.  
5. Capture `app_cmd_menu_language` with `$()`.  
6. Translate operational `rm` sentences, JSON about, or the `version` one-liner in this change.  
7. Put `language` on the argv verb list.

---

## 5. Definition of done

| ID | Where | Status |
|----|-------|--------|
| **TP-CLI-24** | `tests/run_dry_run.sh` | have |

`TP-CLI-24` sets `HOME` under the suite scratch directory. It does not execute a real `rm` and it does not remove a directory. It proves row **5**, the thirteen saves, Back, an unrecognized line, `SRM_LANG`, mode **0600**, reserved warns, Japanese and Korean help and about headings, that JSON about keys stay English, and that `language` is not an argv verb.

---

## 6. Related artifacts

| Artifact | Relationship |
|----------|----------------|
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Front **1** / **8** / **9** and the nested boards |
| `docs/requirements/requirement-shell-cli-storage.md` | Persistence directory that holds the leaf |
| `docs/requirements/requirement-shell-cli-interface.md` | `menu` / `help` / `about` surface |
| `docs/requirements/requirement-shell-modular-function-design.md` | `app_` prefix |
| `src/safe-rm` | `app_lang_load`, `app_menu_text`, `app_cmd_menu_language` |

---

**Last Updated**: 2026-10-02 (1.0.0 — front **5**, thirteen codes, leaf `language`)  
**Owner**: safe-rm project maintainers  
**Alignment:** requirement-shell-cli-default-interaction · requirement-shell-cli-storage · requirement-shell-cli-interface · requirement-shell-modular-function-design · CIAO / CIAO-Lite
