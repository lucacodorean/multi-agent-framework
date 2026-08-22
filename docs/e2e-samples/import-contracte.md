# Sample — import contracte de finanțare (DDEV, epic OIRP-8)

Standalone operator walkthrough for the testing team. Not a specification, not a living
story, not a runtime topology. No other document points here.

Covers the four implemented stories of this epic, in the order an officer actually hits
them: import the contracting workbook (AS-006), extract lider / partener (AS-007), decide
exceptions (AS-008), reimport with versioning (AS-009).

Use the three specimen workbooks as they sit in the tree. Do not re-save them under new
headers. Do not paste CSV into **Preluarea asocierilor** — that is a different screen.

App locale on a stock DDEV boot is Romanian (`APP_LOCALE=ro`). Register screens are
Romanian either way. Login chrome follows Filament locale.

## 0. Files, account, path

Workbooks (byte-identical copies also live under `tests/Fixtures/contracte/`):

| File | Sheet | Data rows | What it is for |
|---|---|---|---|
| `docs/stories/support/SMIS_CUI.xlsx` | `Sheet1` | 240 | First import |
| `docs/stories/support/SMIS_CUI_Reimport_Test_cu_4_entitati_noi.xlsx` | `Contracte` | 244 | Reimport: 4 new SMIS, 9 new CUI |
| `docs/stories/support/SMIS_CUI_Reimport_Test_cu_conflict.xlsx` | `Contracte_Reimport` | 245 | Reimport: duplicate SMIS, name conflict, lider=partener |

Headers the engine maps (row 1; do not rename): `FOND UE  [FSE+]`, `COD APEL`,
`Titlu apel`, `Prioritate de investitii`, `Numar apel`, `CodSMIS`, `Titlu proiect`,
`CUI LIDER`, `SOLICITANT (LIDER)`, `PARTENERI-CUI`. The fond header cell contains a
newline; that is expected.

Open `http://oir-flow.ddev.site/oir-west/autentificare`.

| Field | Value |
|---|---|
| Email | `ier@oir-west.dev` (or `admin@oir-west.dev`) |
| Password | `oirflow-dev` |

Submit. Land on the tenant panel, brand **Cereri de Rambursare/Plată**. Left nav: expand
**Registrul de risc**.

Do not use `/consola` (or `/console`). Do not use a **Coordonator** or **Ofițer de
verificare** account — those roles do not hold `risk-register.access` and get 403 on
every screen below.

Standing local machine after the `oir-north` rename: path `/oir-north-west/autentificare`.
The declared seeder still lists `oir-north`; that slug is spent. Prefer `oir-west`.

The engine container must be up. The platform never opens the `.xlsx`; a dead engine is a
red callout, not a partial import.

## 1. First import — `SMIS_CUI.xlsx`

Click **Importă coduri SMIS**
(`http://oir-flow.ddev.site/oir-west/import-contracte`).

Title: **Importul contractelor de finanțare**. Subheading mentions one version per
import. Empty table heading, if this tenant has never imported: **Niciun import de
contracte**.

| Field | Value |
|---|---|
| **Fișierul de contracte (.xlsx)** | `SMIS_CUI.xlsx` |

Accepted type is Excel `.xlsx` only (max 8 MiB; these specimens are ~33 KiB). There is no
paste box.

Click **Importă coduri SMIS**.

Expect a success toast:

- title **Fișier importat — versiunea 1**
- body **240 linii preluate, 0 invalide, 32 decizii în așteptare.**

The page redirects to `{document}/elemente` (Romanian path, not `/items`). Example:
`http://oir-flow.ddev.site/oir-west/import-contracte/<uuid>/elemente`.

The import does not fail globally because of non-conforming partner cells. 0 invalid
lines is correct: malformed partners wait as questions; they do not sink the row.

## 2. What the first import produced

Title: **Elementele importului — versiunea 1**. Subheading carries the filename, the
author email, the import timestamp, and **liniile invalide sunt primele.**

Yellow callout **Documentul este în lucru** — **32 decizii nu au fost încă luate.**
Button **Deciziile de luat**. Summary text: **240 linii, dintre care 0 invalide.
Versiunea 1, ultima importată.**

Table columns, in order: **Rândul din fișier**, **Status**, **Cod SMIS**, **Titlu
proiect**, **Lider**, **Parteneri**, **Decizii în așteptare**, **Asertiunea curentă**.
No column is sortable. Status badges: **Validă** / **Invalidă**.

Spot-check row 2 (first data row; Excel row 2, because row 1 is the header):

| | |
|---|---|
| Rândul din fișier | `2` |
| Status | **Validă** |
| Cod SMIS | `300907` |
| Titlu proiect | starts with `NGO MATCHES` |
| Lider | `ASOCIATIA PENTRU PROMOVAREA AFACERILOR IN ROMANIA — 18261599` |
| Parteneri | `1` |
| Decizii în așteptare | `0` |
| Asertiunea curentă | **Această linie** |

Click **Detaliere**. Modal **Rândul 2 din fișier**. Expect:

- **Celula PARTENERI-CUI, exact cum a fost primită** = `FUNDATIA LAM - 11249172`
- **Entități preluate din această linie** = `FUNDATIA LAM — 11249172`
- **Excepții** = **Nicio excepție pe această linie.**
- **Închide**

The seven project fields (SMIS, title, fond, call code, call title, investment
priority, call number) are stored on the project. This screen shows SMIS and title.
Fond / apel / prioritate are not rendered on any Filament form today — do not file a
bug that they are “missing from **Proiecte și entități**”; they were never put on that
form. Verify title via **Consultare registru** / **Proiecte și entități** (step 5).

Values are trimmed before compare and store. The one exception is the composite
`PARTENERI-CUI` cell, kept verbatim (trailing spaces on row 6’s cell are visible in
**Detaliere**).

## 3. Entity extraction — what to look for in the items list

Lider is always first: name from `SOLICITANT (LIDER)`, fiscal code from `CUI LIDER`.
Partners come only from `PARTENERI-CUI`, split on `;` alone. A comma is not an entity
separator.

| Excel row | Cod SMIS | What the platform did |
|---|---|---|
| 2 | `300907` | 1 partner `FUNDATIA LAM - 11249172` |
| 5 | `301898` | cell `NA` → 0 partners |
| 6 | `302213` | first fragment has a comma in the registered name → **no** partner invented from that fragment; question for a person (step 4) |
| 33 | `312506` | cell `FIATEST SRL-449981,UNIVERSITATEA BABES BOLYAI-4305849` — no `" - "` → **no** entity; question for a person |
| 17 | `308454` | partner `AGENTIA JUDETEANA PENTRU OCUPAREA FORTEI DE MUNCA MARAMURES - 3627064` |
| 73 | `336961` | lider `AGENTIA JUDETEANA PENTRU OCUPAREA FORTEI DE MUNCA` with the same CUI `3627064` — name conflict on the company grain, not on one row |
| 135 | `309476` | glued `P1: …, P2: …` fragment → 0 partners taken from that cell |
| 136 | `309524` | same shape |

`NA` (any case, trimmed) and a blank `PARTENERI-CUI` cell both mean “no partners”. The
base file writes `NA` on 120 rows. The two reimport files leave the cell empty on 121
rows instead.

Fiscal codes are canonicalized on the platform (RB-09): upper-case, drop
non-alphanumerics, drop a leading two-letter country prefix when digits remain, then
accept 2–10 digits. The engine returns codes as written. Specimens already look like
digits; `RO 12.345.678` would land as `12345678`.

Counts after this file, before any decision:

- 240 projects created
- 96 partner occurrences extracted from 127 `;`-fragments (27 unsplit + 4 comma-bearing
  fragments wait; unique usable CUI across lider+partener is 161)
- 1 contested fiscal code (`3627064`)
- 32 pending decisions = 27 + 4 + 1

## 4. Exception screen — human decisions

From the yellow callout, click **Deciziile de luat**
(`…/import-contracte/<uuid>/exceptii`).

Title: **Deciziile importului — versiunea 1**. Subheading: **Liniile și codurile
fiscale pe care platforma refuză să le decidă singură.** Callout still **Documentul
este în lucru**, now **Acum sunt 32.** Link **Elementele importate** goes back.

Table: one row per unanswered question, line questions first, then company-name
questions. Columns: **Unde**, **Ce trebuie decis**, **Cum apare în fișier**,
**Valoarea propusă automat**.

Find these four representative rows (the other 28 are the same two partner-fragment
shapes). Do not try to close all 32 unless you have time; a later import is allowed
while this document stays `în lucru`.

### 4a. Contested company name (grain = fiscal code)

| | |
|---|---|
| Unde | **Codul fiscal 3627064** |
| Ce trebuie decis | **Codul fiscal apare în fișier cu mai multe denumiri.** |
| Cum apare în fișier | the two spellings, joined with ` · ` |
| Valoarea propusă automat | `AGENTIA JUDETEANA PENTRU OCUPAREA FORTEI DE MUNCA MARAMURES` (first spelling in the file) |

Until this is decided, **Consultare registru** shows this entity without a name
(`—`). The fiscal code already exists.

Click **Decid**. Choose one radio option, or **Altă denumire, pe care o scriu eu**.
Helper text: the choice applies to every project **of this import version**. Click
**Salvează decizia**.

Toast **Decizia a fost salvată** / **Au mai rămas N decizii de luat.**

A blank “other” name is refused: **Nu ați indicat nicio denumire.** A name longer
than 255 characters is refused: **Denumirea introdusă este mai lungă decât o poate
păstra registrul: cel mult 255 caractere.** Nothing is truncated.

### 4b. Fragment that does not split (`" - "` missing or too many parts)

Find **Rândul 33 din fișier**.

| | |
|---|---|
| Ce trebuie decis | **Fragmentul din coloana PARTENERI-CUI nu se împarte în denumire și cod fiscal; corectați-l pentru ca entitatea să poată fi adăugată.** |
| Cum apare în fișier | `FIATEST SRL-449981,UNIVERSITATEA BABES BOLYAI-4305849` |
| Valoarea propusă automat | **— (nu se preia nimic)** |

Click **Decid**. Field **Valoarea care se salvează**. Format `DENUMIRE - CUI` (spaces
around the hyphen). Leave empty to refuse the entity — a refusal is a decision.

Happy path: type `FIATEST SRL - 449981` → **Salvează decizia**. That creates entity
`449981` named `FIATEST SRL` and attaches it as **Partener** on SMIS `312506`. The
second company in the original cell is not invented; only what you typed is taken.

A value that is not `DENUMIRE - CUI` with a usable CUI, or that repeats an entity
already on the line, is refused and the question stays open.

### 4c. Fragment that splits cleanly but contains a comma

Find **Rândul 6 din fișier** (and later 77, 135, 136 — same reason).

| | |
|---|---|
| Ce trebuie decis | **Fragmentul din coloana PARTENERI-CUI conține o virgulă: confirmați că este o singură entitate sau corectați-l.** |
| Cum apare în fișier | `FUNDATIA EUROPEANA PENTRU CONSULTANTA, IMPLEMENTARE SI DEZVOLTARE -FECID - 23906047` |
| Valoarea propusă automat | the automatic split, offered as a suggestion only |

Row 6 is one registered name that contains a comma. Rows 135 and 136 pack two
companies into one fragment (`P1: …, P2: …`). The platform cannot tell the two
shapes apart, so a person must confirm. Accept the suggestion on row 6; on 135/136
edit into two decisions’ worth of `DENUMIRE - CUI` or refuse.

### 4d. Questions that only need acknowledgement

Not present on the first file. They appear on the conflict workbook (step 7):
duplicate SMIS, lider-and-partener, missing SMIS, over-long cell, engine-unreadable
row. The modal then has no value field — submit **Salvează decizia** to take it to
knowledge. That closes the **question**, not the **defect**. An invalid line stays
**Invalidă**.

When the last pending decision of a document is saved, toast body becomes **Nu mai
există excepții nedecise: documentul nu mai este în lucru.** Callout turns green
**Documentul este închis**. Empty table: **Nicio decizie în așteptare**.

## 5. Register after the first import

**Consultare registru** (`http://oir-flow.ddev.site/oir-west/registru-risc`).

Title **Registrul de risc**. Callout **240 proiecte în tenantul curent**. IER columns
show **Date lipsă** until indices are ingested — out of this sample.

Find SMIS `300907`:

| Cod SMIS | Denumire proiect | Lider de parteneriat | Entități |
|---|---|---|---|
| `300907` | starts with `NGO MATCHES` | `ASOCIATIA PENTRU PROMOVAREA AFACERILOR IN ROMANIA (18261599)` | `2` |

**Detaliere** → **Proiect SMIS 300907 — entități**: lider `18261599`, partener
`11249172` (`FUNDATIA LAM`). **Închide**.

If you completed 4b, SMIS `312506` now has one extra partener `449981`.

**Proiecte și entități** (`…/proiecte`): same 240 rows, columns **Cod SMIS**,
**Denumire**, **Entități**. Create/edit still only asks for SMIS + denumire +
entities — the extra contract-metadata columns are not on this form.

## 6. Reimport with four new projects — last import is source of truth

Stay on **Importă coduri SMIS**. The table now has one row:

| Versiune | Fișier | Linii (invalide) | Decizii în așteptare | În lucru | Ultima versiune |
|---|---|---|---|---|---|
| `v1` | `SMIS_CUI.xlsx` | `240 (0)` | 32 or fewer | clock if you left questions | true |

Row actions: **Elementele importate**, **Deciziile de luat** (only while în lucru),
**Descarcă fișierul păstrat**.

Upload `SMIS_CUI_Reimport_Test_cu_4_entitati_noi.xlsx`. Click **Importă coduri SMIS**.

Toast: **Fișier importat — versiunea 2** / **244 linii preluate, 0 invalide, 32
decizii în așteptare.** Redirect to v2’s `{document}/elemente`.

This is allowed even if v1 is still **în lucru**. v1 stays open; its remaining
decisions apply only to v1. v1’s **Ultima versiune** becomes false. v1 items show
**Asertiunea curentă** = **Versiunea 2** for every SMIS that v2 also named (this
file names all 240 originals).

v2 adds exactly:

| Cod SMIS | Titlu | Lider | Partners |
|---|---|---|---|
| `900001` | `Proiect test reimport 001` | `ENTITATE TEST ALFA SRL` `99000001` | `99000002`, `99000003` |
| `900002` | `Proiect test reimport 002` | `ENTITATE TEST DELTA SRL` `99000004` | `99000005` |
| `900003` | `Proiect test reimport 003` | `ENTITATE TEST ZETA SRL` `99000006` | `99000007`, `99000008` |
| `900004` | `Proiect test reimport 004` | `ENTITATE TEST IOTA SRL` `99000009` | none (empty cell) |

Nine new fiscal codes `99000001`–`99000009`. Existing project↔entity pairs are not
duplicated. Same lider restated → no replacement.

**Consultare registru** callout **244 proiecte în tenantul curent**.

Back on the import list: two rows, newest first (`v2` then `v1`). Download v1’s
**Descarcă fișierul păstrat** — browser saves `SMIS_CUI.xlsx`, bytes identical to
what you uploaded. Repeat for v2.

## 7. Conflict reimport — invalid line + human questions that do not repair it

Upload `SMIS_CUI_Reimport_Test_cu_conflict.xlsx`.

Toast: **Fișier importat — versiunea 3** / **245 linii preluate, 1 invalide, 35
decizii în așteptare.** (35 = the same 31 partner-fragment questions + 1 name
conflict on `3627064` + 1 name conflict on `18261599` + 1 duplicate-SMIS
acknowledgement + 1 lider-and-partener acknowledgement.)

On `{document}/elemente` the **invalid line is first**, even though it is Excel row
242:

1. row `242` **Invalidă** SMIS `300907`
2. then valid rows in source order, starting at row `2` also SMIS `300907`

Row 242 **Detaliere**:

- PARTENERI-CUI = `ENTITATE CONFLICT SRL - 18261599`
- exceptions include:
  - **Codul SMIS apare de mai multe ori în același fișier; a fost preluată prima apariție.** `[300907]`
  - **Aceeași entitate apare și ca lider, și ca partener pe același proiect; a fost păstrată calitatea de lider.**

Confirm both on **Deciziile de luat**. After acknowledgement, row 242 is still
**Invalidă**. The register still asserts row 2 of this version (or the previous
latest valid line for `300907`): lider `18261599`, partner `FUNDATIA LAM` only.
`ENTITATE CONFLICT SRL` is not attached as a second quality on that project.

Four new SMIS, same pattern as step 6: `910001`–`910004`, CUI `99100001`–`99100008`.
**Consultare registru** now **248** if you imported all three files in sequence
(240 + 4 + 4).

On the company grain, **Codul fiscal 18261599** now has three candidate names
(original, `… DENUMIRE MODIFICATA`, `ENTITATE CONFLICT SRL`). Choose the modified
one if you want the register’s current name to follow this file; that choice does
not rewrite v1/v2’s stored assertion.

## 8. Version table — what “classified, not deleted” looks like

`http://oir-flow.ddev.site/oir-west/import-contracte`

| Versiune | Linii (invalide) | În lucru | Ultima versiune |
|---|---|---|---|
| `v3` | `245 (1)` | clock while 35 (or fewer) pending | true |
| `v2` | `244 (0)` | clock if you left its 32 | false |
| `v1` | `240 (0)` | clock if you left its 32 | false |

Open v1 **Elementele importate**. Summary: **Versiunea 1, clasată de un import
ulterior.** Each original SMIS: **Asertiunea curentă** names the later version that
currently holds it (2 or 3). The rows are still there. A decision you now take on v1
is stored on v1 and does **not** change the register, because v1 no longer holds
`is_latest` for those grains.

The application renders “current” from the stored **Ultima versiune** / per-row
`is_latest` flag, not by computing `max(version)` on read.

## 9. Refusals worth hitting once

On **Importă coduri SMIS**, submit with no file:

- danger callout **Importul a fost respins** / **Nu ați încărcat niciun fișier.**
- toast with the same heading
- register unchanged

A non-xlsx name/type: **Fișierul nu poate fi trimis motorului de documente**.

Engine unreachable / unusable parse: **Motorul de documente nu a putut citi
fișierul** — **Registrul nu a fost modificat.**

A Coordonator session against `/oir-west/import-contracte` (and the two
`{document}` URLs): 403.

Unknown `{document}` uuid: 404, not an empty list.

## 10. What these three files do not demonstrate

Still true in the product; just not exercisable with the specimens.

- **A SMIS the new file omits stays rendered from the previous version.** Both
  reimport workbooks repeat all 240 original codes. The rule is: latest *mention*
  wins per SMIS; absence is not a delete.
- **A later file’s lider replaces the previous lider** on that project (dropped, not
  demoted). All three specimens name the same lider per project.
- **Two simultaneous imports, different liders, last commit wins** — both officers
  finish without an error. Not a single-browser walkthrough.
- **A cell longer than the register column** (SMIS 64, title 255, fond 64, call code
  128, call number 32, entity name 255; call title and investment priority are
  unbounded `text`). Makes that line **Invalidă**, import continues, decision cannot
  shorten the source cell — correct the file and reimport. No specimen overflows.
- **Empty `PARTENERI-CUI` vs `NA`** — already covered by using the base file then a
  reimport file; both yield zero partners on those rows.

## If a screen looks empty / wrong

- **Niciun import de contracte** — step 1 did not land. Stay on **Importă coduri
  SMIS**, not **Preluarea asocierilor**.
- Toast **0 invalide** on the first file, but 32 decisions — expected. Invalid ≠
  “has a partner question”.
- **Consultare registru** still **Registrul este gol** — import redirected but
  projection did not write; engine/store refusal. Re-read the red callout on the
  import page. Do not open **Registrul cererilor**.
- SMIS `300907` has a new partner `ENTITATE CONFLICT SRL` after step 7 — the
  duplicate row was treated as valid. It must not be.
- Sidebar has no **Registrul de risc** — wrong role or `/consola`.
- `/oir-west/login` is 404. Login is `/autentificare`. Items are `/elemente`, not
  `/items`. Console is `/consola`, not `/console`.
