# support — material supplied with an input

Files the submitter supplied alongside an input, kept as the evidence the
documents specifying that input cite.

## Contents

- `SMIS_CUI.xlsx`, `SMIS_CUI_Reimport_Test_cu_4_entitati_noi.xlsx`,
  `SMIS_CUI_Reimport_Test_cu_conflict.xlsx` — supplied with the OIRP-8
  contract-import epic. What each workbook holds and what it proves is specified
  in `docs/tracker/2026-08-18-oirp-8-contract-import-intake.md` and
  `docs/tracker/2026-08-18-oirp-8-contract-import-ruled-intake.md`. Read it
  there; never restate it here.
- `Cap_tabel_document_registru_IER_de_la_Minister.xlsx` — the header of the
  Indici Expunere la Risc register table, supplied by the Ministry with the
  OIRP-26 epic. What it holds and which columns are read is specified in
  `epic3.md`. Read it there; never restate it here.

## Rules

- Nobody writes here. New material arrives only by explicit human instruction
  naming the file, the way these did.
- Reading is unrestricted. No `HISTORY-ACCESS:` gate applies — that gate covers
  `docs/stories/as-reference/` only.
- Tracked in git: committed documents cite these paths as evidence.
- Non-re-derivable sole-record input — the class ADR-0027 defines for
  `docs/tracker/`. Write once, never regenerate over a file; supersede with a
  later file when the submitter sends new material.
- This directory is canonical. The byte-identical copies under
  `tests/Fixtures/contracte/` and `engine/tests/fixtures/contracte/` are derived
  from it; on divergence the file here wins and the copy is refreshed.
