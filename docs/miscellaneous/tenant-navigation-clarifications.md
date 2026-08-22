# Clarificări de navigare — panoul tenant

Ce sunt, de fapt, patru intrări din grupul **Registrul de risc** al panoului tenant
(prefix de cale `{tenant}`, `app/Providers/Filament/AppPanelProvider.php`).

Hartă de navigare, nu set de reguli: regulile stau în `docs/stories/as-is/` și sunt
citate aici doar prin id. Grupul mai conține „Preluarea asocierilor” (`preluare-asocieri`)
și „Istoricul surselor” (`istoric-surse-indici`), care nu fac obiectul acestui document.

## Proiecte și entități → `{tenant}/proiecte`

Sursă: `app/Filament/Resources/Projects/ProjectResource.php`, model `App\Models\Project`.

- Un rând = un contract de finanțare, plus liderul și partenerii lui. Identitatea este codul
  SMIS, unic în interiorul tenantului (RB-11) — `app/Models/Project.php`.
- Tabelul tenant `projects` poartă metadatele contractului (`fond`, `cod_apel`, `titlu_apel`,
  `prioritate_investitii`, `numar_apel`), iar `Titlu proiect` ESTE `projects.name` —
  `database/migrations/tenant/2026_08_18_102200_add_contract_metadata_to_projects_table.php`,
  AS-006.
- Nu este alias al unui ecran separat „Contracte de finanțare”: un asemenea ecran nu există.
  Sintagma este titlul paginii de import — `ImportContracts::getTitle()`.
- Listarea arată doar `Cod SMIS`, `Denumire`, `Entități` (număr), `Modificat`; niciuna dintre
  cele cinci coloane de metadate.
- Rute: `/proiecte`, `/proiecte/creare`, `/proiecte/{record}/editare`
  (`ProjectResource::getPages()`). Nu există rută de vizualizare `/proiecte/{id}`.

## Importă coduri SMIS → `{tenant}/import-contracte`

Sursă: `app/Filament/Pages/ImportContracts.php`.

- Alimentează „Proiecte și entități”: `App\RiskRegister\ContractImport` →
  `App\RiskRegister\ContractImportProjection` scrie `projects`, `entities`, `project_entity` —
  aceleași tabele pe care le listează `ProjectResource`.
- Nu este singura sursă. Trei căi scriu aceleași trei tabele:
  1. importul acestui registru de lucru, prin `ContractImportProjection`;
  2. „Preluarea asocierilor” (`preluare-asocieri`, `app/Filament/Pages/ImportAssociations.php`
     → `app/RiskRegister/AssociationImport.php`), care există pentru că profilul `associations`
     al motorului răspunde încă 501 (`engine/app/tabular.py`);
  3. înregistrarea manuală de pe `proiecte`, prin `app/RiskRegister/ManualProjectRegistration.php`.
  Doar calea 1 trece prin `ContractImportProjection`; căile 2 și 3 scriu direct în tabele.
- Pagina este mai mult decât un încărcător: o versiune per import, ultimul import fiind sursa de
  adevăr (AS-009), registrul de lucru păstrat octet cu octet și descărcabil, plus paginile-copil
  `import-contracte/{document}/elemente` (`ContractImportItems::getRoutePath()`) și
  `import-contracte/{document}/exceptii` (AS-008), unde liniile care cer decizie umană se rezolvă.
  Deciziile ajung în aceleași tabele prin `app/RiskRegister/ContractImportDecisions.php`.

## Preluarea indicilor → `{tenant}/preluare-indici`

Sursă: `app/Filament/Pages/IngestRiskIndex.php`.

- Sursa de date este Anexa 3, lista IER a ministerului, citită de motor la `POST /anexa3/parse`
  (`app/RiskRegister/Anexa3Ingest.php`, `App\Engine\EngineClient::parseAnexa3`) — NU prin profilul
  `ier-list` al lui `POST /tabular/parse`, care nu are niciun consumator în `app/` și răspunde 501.
- Nu este o listare a fișierului, ci actul de preluare: declară o perioadă de validitate, reține
  sursa și deschide o versiune de registru (AS-016, AS-018) prin
  `RiskRegisterVersionRepository::openFromSource()`, apelat din `app/RiskRegister/RiskIndexIngest.php`.
- Acceptă în egală măsură transcrierea manuală integrală — text lipit sau UTF-8 delimitat (AS-014).
  Fișier și text împreună se refuză.
- Ce s-a preluat se vede în altă parte: `istoric-surse-indici` („Istoricul surselor”,
  `app/Filament/Pages/RiskIndexSourceHistory.php`) pentru surse, `registru-risc` pentru valori.

## Consultare registru → `{tenant}/registru-risc`

Sursă: `app/Filament/Pages/ConsultRiskRegister.php`.

- Instantaneu înghețat, nu agregat viu: citește doar `risk_register_versions` /
  `risk_register_entries` (`app/RiskRegister/Storage/TenantRiskRegisterVersionRepository.php`).
  Fără join viu pe `Project`, fără determinare, fără apel la motor. Cu proiecte înregistrate și
  nicio sursă IER preluată vreodată, registrul este gol
  (`tests/Feature/RiskRegister/RiskRegisterConsultationTest.php`).
- Asamblarea este condusă de preluarea IER: o preluare reușită deschide o versiune, iar în acel
  moment setul de asocieri se copiază și IER-ul se suprapune numai după CUI (AS-017, AS-019).
- CUI-urile prezente doar în sursa IER, fără rând SMIS în versiune, nu apar — valorile lor rămân
  în magazia de indici. Entitățile fără indice apar „Date lipsă”, nu primesc clasă și nu contribuie
  la maximul proiectului.
- A treia intrare: clasa și procentul de verificare nu se stochează în versiune, ci sunt o proiecție
  la citire din setul ACTIV FINAL de intervale (`intervale-clase-risc` →
  `app/RiskRegister/RiskClassIntervals.php` → `app/RiskRegister/RiskClassAssignment.php`, aplicat în
  `RiskRegisterConsultation::withAssignments()`). Un set activ provizoriu lasă clasa și procentul
  goale. Maximul IER pe proiect se calculează tot la citire (AS-021).
- Într-o singură propoziție: un instantaneu versionat al proiecției contractelor, valorizat pe CUI
  dintr-o singură sursă IER, clasificat la citire de setul activ de intervale.
