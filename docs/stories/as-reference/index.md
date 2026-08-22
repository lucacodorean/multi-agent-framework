# Colecția de referință — index

Bazin de referință, nu specificație: cele 156 de elemente de mai jos (22 UC + 134 US) au fost fuzionate la 2026-08-14 din trei surse — corpusul Prototype A, documentul Stub (2026-08-13) și documentul Wiki (2026-08-13) — și nu guvernează nimic; se consultă la nevoie sau la cererea utilizatorului. Cele trei surse au fost eliminate odată cu `docs/legacy/` (recuperabile din istoricul git); acest fișier este singurul loc din arbore în care spațiile de identificatori retrase `US-A-###` / `US-B-###` / `US-C-###` (și omoloagele `UC-`) se mai rezolvă.

## Elemente (156)

| id | titlu | coverage | overlay | implementation | modul | surse |
|---|---|---|---|---|---|---|
| [UC-001](UC-001-provizionarea-unui-tenant-nou.md) | Provizionarea unui tenant nou | a-only | unchanged | implemented | tenancy-provisioning | UC-A-011 |
| [UC-002](UC-002-configurarea-aplicatiei.md) | Configurarea aplicației | stub-only | new | unknown | — | UC-B-013 |
| [UC-003](UC-003-activarea-contului-unui-utilizator-nou.md) | Activarea contului unui utilizator nou | draft | new | unknown | — | UC-C-015 |
| [UC-004](UC-004-importul-contractelor-de-finantare-in-registrul.md) | Importul contractelor de finanțare în registrul de risc | team-reviewed | modified | partial | risk-register | UC-C-012, UC-B-008, UC-A-009 |
| [UC-005](UC-005-importul-anexei-iii-actualizarea-indicilor-si.md) | Importul Anexei III, actualizarea indicilor și versionarea registrului de risc | team-reviewed | modified | partial | risk-register | UC-C-013, UC-B-008, UC-A-008 |
| [UC-006](UC-006-inregistrarea-unei-investigatii-externe.md) | Înregistrarea unei investigații externe | draft | new | unknown | — | UC-C-014, UC-B-009 |
| [UC-007](UC-007-inregistrarea-unei-cereri-cr-cp-in.md) | Înregistrarea unei cereri CR/CP în platformă | draft | modified | partial | dosar-lifecycle | UC-C-001, UC-B-001, UC-A-001 |
| [UC-008](UC-008-asignarea-ofiterilor-si-a-responsabilului-ier.md) | Asignarea ofițerilor și a responsabilului IER | draft | new | unknown | — | UC-C-002 |
| [UC-009](UC-009-incarcarea-fisierului-de-cheltuieli-si-verificarea.md) | Încărcarea fișierului de cheltuieli și verificarea preliminară | draft | modified | implemented | preliminary-verification | UC-C-003, UC-B-002, UC-A-002 |
| [UC-010](UC-010-tratarea-liniilor-fara-cod-de-achizitie.md) | Tratarea liniilor fără cod de achiziție | draft | modified | partial | preliminary-verification | UC-C-004, UC-B-003, UC-A-003 |
| [UC-011](UC-011-validarea-de-catre-ofiterul-2.md) | Validarea de către ofițerul 2 | draft | new | unknown | — | UC-C-005, UC-B-004 |
| [UC-012](UC-012-solicitarea-de-clarificari-catre-beneficiar-si.md) | Solicitarea de clarificări către beneficiar și reluarea verificării | draft | modified | partial | preliminary-verification | UC-C-006, UC-B-003, UC-A-003 |
| [UC-013](UC-013-generarea-notei-justificative.md) | Generarea notei justificative | draft | modified | partial | nj-documents | UC-C-007, UC-B-005, UC-A-004 |
| [UC-014](UC-014-verificarea-semnaturilor-pe-nota-justificativa.md) | Verificarea semnăturilor pe nota justificativă | draft | modified | partial | signature-circuit | UC-C-008, UC-B-005, UC-A-005 |
| [UC-015](UC-015-generarea-scriptului-si-a-folderelor-pentru.md) | Generarea scriptului și a folderelor pentru IDEA | draft | new | unknown | — | UC-C-009 |
| [UC-016](UC-016-executarea-esantionarii-in-idea-si-salvarea.md) | Executarea eșantionării în IDEA și salvarea istoricului | draft | modified | partial | sampling | UC-C-010, UC-B-006, UC-A-006 |
| [UC-017](UC-017-notificarea-de-esantionare-si-hand-off.md) | Notificarea de eșantionare și hand-off către achiziții | draft | new | unknown | — | UC-C-011 |
| [UC-018](UC-018-verificarea-esantionului-si-emiterea-rezultatului.md) | Verificarea eșantionului și emiterea rezultatului | pre-wiki | modified | partial | sample-verification | UC-B-007, UC-A-007 |
| [UC-019](UC-019-monitorizarea-portofoliului-de-cereri.md) | Monitorizarea portofoliului de cereri | a-only | unchanged | partial | dosar-lifecycle | UC-A-010 |
| [UC-020](UC-020-inregistrarea-unei-achizitii-si-desemnarea-ofiterilor.md) | Înregistrarea unei achiziții și desemnarea ofițerilor de verificare | stub-only | deferred | unknown | — | UC-B-010 |
| [UC-021](UC-021-verificarea-unei-achizitii-directe-ofiter-1.md) | Verificarea unei achiziții directe (Ofițer 1, 9 etape) | stub-only | deferred | unknown | — | UC-B-011 |
| [UC-022](UC-022-solicitarea-inlocuirii-unui-ofiter-de-achizitii.md) | Solicitarea înlocuirii unui ofițer de achiziții aflat în conflict de interese | stub-only | deferred | unknown | — | UC-B-012 |
| [US-001](US-001-autentificare-reala-cu-roluri-atribuite-de.md) | Autentificare reală cu roluri atribuite de server | pre-wiki | modified | implemented | auth-access | US-B-001, US-A-001 |
| [US-002](US-002-autorizare-pe-roluri.md) | Autorizare pe roluri | pre-wiki | unchanged | partial | auth-access | US-B-003, US-A-002 |
| [US-003](US-003-navigare-in-functie-de-rol.md) | Navigare în funcție de rol | stub-only | new | unknown | — | US-B-002 |
| [US-004](US-004-incheierea-sesiunii.md) | Încheierea sesiunii | a-only | unchanged | implemented | auth-access | US-A-003 |
| [US-005](US-005-adaugarea-unei-persoane-in-tenant.md) | Adăugarea unei persoane în tenant | draft | modified | implemented | persons-projects | US-C-001, US-B-003, US-A-048 |
| [US-006](US-006-gestionarea-plecarilor-din-organizatie.md) | Gestionarea plecărilor din organizație | draft | modified | implemented | persons-projects | US-C-002, US-B-003, US-A-048 |
| [US-007](US-007-activarea-contului-prin-link-trimis-pe.md) | Activarea contului prin link trimis pe email | draft | new | unknown | — | US-C-003 |
| [US-008](US-008-resetarea-parolei-uitate.md) | Resetarea parolei uitate | draft | new | unknown | — | US-C-004 |
| [US-009](US-009-izolarea-datelor-pe-tenant.md) | Izolarea datelor pe tenant | draft | new | unknown | — | US-C-005 |
| [US-010](US-010-configurarea-serverului-smtp.md) | Configurarea serverului SMTP | stub-only | new | unknown | — | US-B-004 |
| [US-011](US-011-configurarea-radacinii-locatiei-de-fisiere.md) | Configurarea rădăcinii locației de fișiere | stub-only | new | unknown | — | US-B-005 |
| [US-012](US-012-administrarea-documentelor-anexa-3.md) | Administrarea documentelor Anexa 3 | stub-only | new | unknown | — | US-B-006 |
| [US-013](US-013-alegerea-modulului-de-verificare.md) | Alegerea modulului de verificare | stub-only | new | unknown | — | US-B-007 |
| [US-014](US-014-interfata-minimalista-pentru-utilizatori-non-tehnici.md) | Interfață minimalistă pentru utilizatori non-tehnici | draft | new | unknown | — | US-C-066 |
| [US-015](US-015-documentarea-solutiei-pentru-replicare-la-alte.md) | Documentarea soluției pentru replicare la alte OIR-uri | draft | new | unknown | — | US-C-067 |
| [US-016](US-016-mediu-de-test-cu-server-de.md) | Mediu de test cu server de email intern | draft | new | unknown | — | US-C-068 |
| [US-017](US-017-instalarea-si-infrastructura-asigurate-de-furnizor.md) | Instalarea și infrastructura asigurate de furnizor | draft | new | unknown | — | US-C-069 |
| [US-018](US-018-crearea-si-provizionarea-unui-tenant.md) | Crearea și provizionarea unui tenant | a-only | unchanged | implemented | tenancy-provisioning | US-A-052 |
| [US-019](US-019-suspendarea-si-reactivarea-unui-tenant.md) | Suspendarea și reactivarea unui tenant | a-only | unchanged | implemented | tenancy-provisioning | US-A-053 |
| [US-020](US-020-administrarea-administratorilor-centrali.md) | Administrarea administratorilor centrali | a-only | unchanged | implemented | central-console | US-A-054 |
| [US-021](US-021-bootstrapul-primului-administrator-de-tenant.md) | Bootstrapul primului administrator de tenant | draft | unchanged | implemented | tenancy-provisioning | US-C-003, US-A-055 |
| [US-022](US-022-vizibilitatea-consolei-limitata-la-metadate-operationale.md) | Vizibilitatea consolei limitată la metadate operaționale | a-only | unchanged | partial | central-console | US-A-056 |
| [US-023](US-023-jurnalul-ciclului-de-viata-al-tenantilor.md) | Jurnalul ciclului de viață al tenanților | a-only | unchanged | implemented | tenancy-provisioning | US-A-057 |
| [US-024](US-024-sloguri-valide-si-sloguri-rezervate.md) | Sloguri valide și sloguri rezervate | a-only | unchanged | partial | tenancy-provisioning | US-A-058 |
| [US-025](US-025-importul-fisierului-de-contracte-de-finantare.md) | Importul fișierului de contracte de finanțare în registrul de risc | team-reviewed | modified | implemented | risk-register | US-C-006, US-B-008, US-A-018 |
| [US-026](US-026-parsarea-listei-de-entitati-asociate-din.md) | Parsarea listei de entități asociate din fișierul de contracte | team-reviewed | new | unknown | — | US-C-007 |
| [US-027](US-027-raportul-de-exceptii-la-import-cu.md) | Raportul de excepții la import, cu decizie umană | team-reviewed | new | unknown | — | US-C-008 |
| [US-028](US-028-reimportul-contractelor-idempotenta-pe-cui-si.md) | Reimportul contractelor: idempotență pe CUI și cod SMIS | team-reviewed | new | unknown | — | US-C-009 |
| [US-029](US-029-inregistrarea-manuala-a-unui-proiect-si.md) | Înregistrarea manuală a unui proiect și a entităților sale | pre-wiki | unchanged | implemented | risk-register | US-B-009, US-A-019 |
| [US-030](US-030-importul-anexei-iii-lista-ier-a.md) | Importul Anexei III (lista IER a ministerului) pe o perioadă de valabilitate declarată | team-reviewed | modified | implemented | risk-register | US-C-010, US-B-010, US-A-020 |
| [US-031](US-031-corelarea-indicilor-de-expunere-la-risc.md) | Corelarea indicilor de expunere la risc cu entitățile pe CUI | team-reviewed | new | unknown | — | US-C-011 |
| [US-032](US-032-istoricul-fisierelor-sursa-ier-preluate-cu.md) | Istoricul fișierelor-sursă IER preluate, cu perioadele lor de valabilitate | pre-wiki | modified | implemented | risk-register | US-B-010, US-A-021 |
| [US-033](US-033-registru-de-risc-versionat-pe-perioade.md) | Registru de risc versionat pe perioade de valabilitate de 6 luni, cu registrele anterioare consultabile | team-reviewed | modified | partial | risk-register | US-C-012, US-B-014, US-A-051 |
| [US-034](US-034-copierea-setului-de-date-la-deschiderea.md) | Copierea setului de date la deschiderea unei perioade noi | team-reviewed | new | unknown | — | US-C-013 |
| [US-035](US-035-selectarea-registrului-de-risc-aplicabil-in.md) | Selectarea registrului de risc aplicabil în funcție de data intrării cererii | draft | modified | partial | nj-documents | US-C-014, US-A-027 |
| [US-036](US-036-clasa-de-risc-a-entitatii-determinata.md) | Clasa de risc a entității, determinată din valoarea IER | team-reviewed | modified | partial | risk-register | US-C-015, US-A-022 |
| [US-037](US-037-clasa-de-risc-a-proiectului-si.md) | Clasa de risc a proiectului și procentul de verificare | team-reviewed | modified | partial | risk-register | US-C-016, US-B-011, US-A-023 |
| [US-038](US-038-consultarea-registrului-de-risc-grupat-pe.md) | Consultarea registrului de risc, grupat pe proiect, cu detaliere la nivel de entitate | pre-wiki | modified | partial | risk-register | US-B-011, US-A-024 |
| [US-039](US-039-inregistrarea-unei-investigatii-externe-pe-o.md) | Înregistrarea unei investigații externe pe o entitate, cu verificare 100% | draft | new | unknown | — | US-C-017, US-B-013 |
| [US-040](US-040-editarea-denumirii-unei-entitati-cu-propagare.md) | Editarea denumirii unei entități, cu propagare pe toate contractele ei | draft | new | unknown | — | US-C-018, US-B-012 |
| [US-041](US-041-crearea-manuala-a-cererii-cu-autocompletare.md) | Crearea manuală a cererii cu autocompletare pe codul SMIS | draft | new | unknown | — | US-C-019 |
| [US-042](US-042-campurile-completate-manual-la-crearea-cererii.md) | Câmpurile completate manual la crearea cererii | draft | new | unknown | — | US-C-020 |
| [US-043](US-043-desemnarea-ofiterului-1-a-ofiterului-2.md) | Desemnarea ofițerului 1, a ofițerului 2 și a responsabilului IER | draft | modified | implemented | dosar-lifecycle | US-C-021, US-B-016, US-A-007 |
| [US-044](US-044-asignarea-nu-blocheaza-salvarea-cererii.md) | Asignarea nu blochează salvarea cererii | draft | new | unknown | — | US-C-022 |
| [US-045](US-045-notificarea-ofiterului-la-asignarea-cererii.md) | Notificarea ofițerului la asignarea cererii | draft | modified | partial | dosar-lifecycle | US-C-023, US-A-010 |
| [US-046](US-046-notificarea-la-schimbarea-ofiterului-asignat.md) | Notificarea la schimbarea ofițerului asignat | draft | new | unknown | — | US-C-024 |
| [US-047](US-047-vizibilitatea-cererilor-in-functie-de-rol.md) | Vizibilitatea cererilor în funcție de rol | draft | new | unknown | — | US-C-025 |
| [US-048](US-048-editarea-cererii-si-notificarea-manuala-de.md) | Editarea cererii și notificarea manuală de către coordonator | draft | new | unknown | — | US-C-026 |
| [US-049](US-049-modificarea-sumelor-pe-cerere-de-catre.md) | Modificarea sumelor pe cerere de către ofițerul 1 | draft | new | unknown | — | US-C-027 |
| [US-050](US-050-actualizarea-cererii-dupa-hand-off.md) | Actualizarea cererii după hand-off | draft | new | unknown | — | US-C-028 |
| [US-051](US-051-preluarea-evidentei-cheltuielilor-cu-extragerea-datelor.md) | Preluarea evidenței cheltuielilor cu extragerea datelor de identificare | draft | modified | partial | expense-ledger | US-C-019, US-B-015, US-A-004 |
| [US-052](US-052-asocierea-numarului-de-inregistrare-oficial-registratura.md) | Asocierea numărului de înregistrare oficial (Registratură/Regista) | draft | modified | implemented | dosar-lifecycle | US-C-020, US-B-019, US-A-005 |
| [US-053](US-053-indicarea-programului-de-finantare.md) | Indicarea programului de finanțare | a-only | unchanged | partial | dosar-lifecycle | US-A-006 |
| [US-054](US-054-semnalarea-datelor-obligatorii-lipsa.md) | Semnalarea datelor obligatorii lipsă | a-only | unchanged | implemented | dosar-lifecycle | US-A-008 |
| [US-055](US-055-constituirea-dosarului.md) | Constituirea dosarului | a-only | unchanged | implemented | dosar-lifecycle | US-A-009 |
| [US-056](US-056-impunerea-ordinii-pasilor.md) | Impunerea ordinii pașilor | a-only | unchanged | implemented | dosar-lifecycle | US-A-016 |
| [US-057](US-057-reflectarea-rezultatului-verificarii-in-starea-dosarului.md) | Reflectarea rezultatului verificării în starea dosarului | a-only | unchanged | partial | dosar-lifecycle | US-A-017 |
| [US-058](US-058-consultarea-registrului-de-cereri.md) | Consultarea registrului de cereri | stub-only | new | unknown | — | US-B-017 |
| [US-059](US-059-stergerea-unei-cereri-cu-confirmare.md) | Ștergerea unei cereri cu confirmare | stub-only | new | unknown | — | US-B-018 |
| [US-060](US-060-incarcarea-fisierului-de-evidenta-a-cheltuielilor.md) | Încărcarea fișierului de evidență a cheltuielilor | draft | new | unknown | — | US-C-029 |
| [US-061](US-061-solicitarea-verificarii-preliminare.md) | Solicitarea verificării preliminare | draft | new | unknown | — | US-C-030 |
| [US-062](US-062-identificarea-liniilor-non-salariale-fara-cod.md) | Identificarea liniilor non-salariale fără cod unic de achiziție | draft | modified | implemented | preliminary-verification | US-C-031, US-B-020, US-A-011 |
| [US-063](US-063-prezentarea-liniilor-neconforme.md) | Prezentarea liniilor neconforme | a-only | unchanged | partial | preliminary-verification | US-A-012 |
| [US-064](US-064-ignorarea-unei-linii-cu-justificare-obligatorie.md) | Ignorarea unei linii cu justificare obligatorie | draft | modified | partial | preliminary-verification | US-C-033, US-B-021, US-A-015 |
| [US-065](US-065-generarea-automata-a-textului-de-clarificare.md) | Generarea automată a textului de clarificare pe linie | draft | modified | implemented | preliminary-verification | US-C-032, US-B-022, US-B-024, US-A-013 |
| [US-066](US-066-gestionarea-observatiilor-pe-linii.md) | Gestionarea observațiilor pe linii | draft | new | unknown | — | US-C-034, US-B-023 |
| [US-067](US-067-blocarea-incarcarii-de-fisiere-dupa-generarea.md) | Blocarea încărcării de fișiere după generarea notei justificative | draft | new | unknown | — | US-C-035 |
| [US-068](US-068-statusul-cererii-pe-parcursul-verificarii.md) | Statusul cererii pe parcursul verificării | draft | new | unknown | — | US-C-036, US-B-028 |
| [US-069](US-069-trimiterea-cererii-catre-ofiterul-2.md) | Trimiterea cererii către ofițerul 2 | draft | new | unknown | — | US-C-037, US-B-026 |
| [US-070](US-070-blocarea-editarii-cat-timp-cererea-este.md) | Blocarea editării cât timp cererea este la ofițerul 2 | draft | new | unknown | — | US-C-038 |
| [US-071](US-071-aprobarea-de-catre-ofiterul-2.md) | Aprobarea de către ofițerul 2 | draft | new | unknown | — | US-C-039, US-B-027 |
| [US-072](US-072-respingerea-cu-retur-la-ofiterul-1.md) | Respingerea cu retur la ofițerul 1 | draft | new | unknown | — | US-C-040, US-B-027 |
| [US-073](US-073-notificarea-ofiterului-1-la-aprobare.md) | Notificarea ofițerului 1 la aprobare | draft | new | unknown | — | US-C-041 |
| [US-074](US-074-istoricul-tranzitiilor-pentru-audit.md) | Istoricul tranzițiilor pentru audit | draft | new | unknown | — | US-C-042 |
| [US-075](US-075-raportarea-duratelor-pe-etape.md) | Raportarea duratelor pe etape | draft | new | unknown | — | US-C-043 |
| [US-076](US-076-preluarea-textului-de-clarificari-pentru-mysmis.md) | Preluarea textului de clarificări pentru MySMIS | draft | new | unknown | — | US-C-044 |
| [US-077](US-077-marcarea-cererii-ca-in-asteptare-de.md) | Marcarea cererii ca în așteptare de clarificări (inferat) | draft | new | unknown | — | US-C-045 |
| [US-078](US-078-reluarea-lucrului-dupa-primirea-informatiilor.md) | Reluarea lucrului după primirea informațiilor | draft | new | unknown | — | US-C-046 |
| [US-079](US-079-reincarcarea-fisierului-de-cheltuieli-corectat.md) | Reîncărcarea fișierului de cheltuieli corectat | draft | modified | implemented | preliminary-verification | US-C-047, US-B-025, US-A-014 |
| [US-080](US-080-determinarea-populatiei-si-a-dimensiunii-esantionului.md) | Determinarea populației și a dimensiunii eșantionului | a-only | unchanged | implemented | population-determination | US-A-025 |
| [US-081](US-081-constituirea-fisierului-de-identificare.md) | Constituirea fișierului de identificare | a-only | unchanged | implemented | population-determination | US-A-026 |
| [US-082](US-082-solicitarea-generarii-notei-justificative.md) | Solicitarea generării notei justificative | draft | new | unknown | — | US-C-048 |
| [US-083](US-083-generarea-notei-justificative-in-word-si.md) | Generarea notei justificative în Word și PDF | draft | modified | implemented | nj-documents | US-C-050, US-B-029, US-A-029 |
| [US-084](US-084-continutul-notei-justificative.md) | Conținutul notei justificative | draft | modified | partial | nj-documents | US-C-051, US-B-029, US-A-028 |
| [US-085](US-085-procesarea-fisierului-de-cheltuieli-si-salvarea.md) | Procesarea fișierului de cheltuieli și salvarea fișierului pentru IDEA | draft | new | unknown | — | US-C-049 |
| [US-086](US-086-regenerarea-notei-justificative.md) | Regenerarea notei justificative | draft | new | unknown | — | US-C-054 |
| [US-087](US-087-doua-semnaturi-pe-nota-justificativa.md) | Două semnături pe nota justificativă | draft | modified | partial | signature-circuit | US-C-052, US-B-030, US-A-031 |
| [US-088](US-088-verificarea-semnaturilor-si-notificarea-ofiterului-2.md) | Verificarea semnăturilor și notificarea ofițerului 2 | draft | modified | partial | signature-circuit | US-C-053, US-B-030, US-A-031 |
| [US-089](US-089-semnarea-notei.md) | Semnarea notei | stub-only | superseded | unknown | — | US-B-032 |
| [US-090](US-090-vizualizarea-notei-in-aplicatie.md) | Vizualizarea notei în aplicație | pre-wiki | modified | implemented | signature-circuit | US-B-031, US-A-033 |
| [US-091](US-091-urmarirea-starii-semnaturilor.md) | Urmărirea stării semnăturilor | draft | modified | partial | signature-circuit | US-C-052, US-B-030, US-A-032 |
| [US-092](US-092-constituirea-dosarului-electronic-arhivat.md) | Constituirea dosarului electronic arhivat | a-only | unchanged | partial | nj-documents | US-A-030 |
| [US-093](US-093-generarea-scriptului-idea-si-a-instructiunilor.md) | Generarea scriptului IDEA și a instrucțiunilor de eșantionare | draft | modified | partial | sampling | US-C-055, US-A-035 |
| [US-094](US-094-generarea-fisierului-de-intrare-fi-pentru.md) | Generarea fișierului de intrare (FI) pentru IDEA | stub-only | new | unknown | — | US-B-033 |
| [US-095](US-095-generarea-conditionata-a-folderelor-de-lucru.md) | Generarea condiționată a folderelor de lucru pentru eșantionare | draft | new | unknown | — | US-C-056, US-B-036 |
| [US-096](US-096-ocolirea-esantionarii-la-grad-de-verificare.md) | Ocolirea eșantionării la grad de verificare 100% | draft | new | unknown | — | US-C-057 |
| [US-097](US-097-notificarea-operatorului-idea-pentru-deschiderea-esantionarii.md) | Notificarea operatorului IDEA pentru deschiderea eșantionării | draft | modified | partial | sampling | US-C-058, US-B-034, US-A-034 |
| [US-098](US-098-executarea-scriptului-de-esantionare-in-idea.md) | Executarea scriptului de eșantionare în IDEA | draft | new | unknown | — | US-C-059, US-B-035 |
| [US-099](US-099-arhivarea-rezultatelor-esantionarii-si-a-istoricului.md) | Arhivarea rezultatelor eșantionării și a istoricului IDEA | draft | new | unknown | — | US-C-060, US-B-036 |
| [US-100](US-100-constatarea-efectuarii-esantionarii-si-verificarea-rezultatelor.md) | Constatarea efectuării eșantionării și verificarea rezultatelor | draft | modified | partial | sampling | US-C-061, US-A-036 |
| [US-101](US-101-preluarea-esantionului-de-cheltuieli-non-salariale.md) | Preluarea eșantionului de cheltuieli non-salariale în platformă | draft | new | unknown | — | US-C-062 |
| [US-102](US-102-notificarea-ca-esantionul-a-fost-generat.md) | Notificarea că eșantionul a fost generat și verificarea poate începe | draft | modified | implemented | sample-verification | US-C-063, US-B-037, US-A-037 |
| [US-103](US-103-hand-off-conditionat-catre-departamentul-de.md) | Hand-off condiționat către departamentul de achiziții | draft | new | unknown | — | US-C-064 |
| [US-104](US-104-registrul-notificarilor-automate-de-flux-trimise.md) | Registrul notificărilor automate de flux, trimise pe email | draft | new | unknown | — | US-C-065, US-B-057 |
| [US-105](US-105-link-direct-din-email-catre-ecranul.md) | Link direct din email către ecranul exact | stub-only | new | unknown | — | US-B-058 |
| [US-106](US-106-inbox-simulat-doar-prototip.md) | Inbox simulat (doar prototip) | stub-only | deprecated | unknown | — | US-B-059 |
| [US-107](US-107-cererile-mele-si-activitate-amanat.md) | „Cererile Mele" și „Activitate" (amânat) | stub-only | deferred | unknown | — | US-B-060 |
| [US-108](US-108-consultarea-liniilor-esantionate-in-aplicatie.md) | Consultarea liniilor eșantionate în aplicație | pre-wiki | modified | partial | sample-verification | US-B-038, US-A-038 |
| [US-109](US-109-consemnarea-constatarii-pe-o-linie-de.md) | Consemnarea constatării pe o linie de eșantion | a-only | unchanged | implemented | sample-verification | US-A-039 |
| [US-110](US-110-emiterea-documentelor-de-rezultat-al-verificarii.md) | Emiterea documentelor de rezultat al verificării eșantionului | pre-wiki | modified | implemented | sample-verification | US-B-039, US-A-040 |
| [US-111](US-111-inchiderea-cererii-dupa-verificarea-liniilor-esantionate.md) | Închiderea cererii după verificarea liniilor eșantionate | stub-only | new | unknown | — | US-B-040 |
| [US-112](US-112-registrul-cererilor-cu-starile-lor.md) | Registrul cererilor cu stările lor | a-only | unchanged | partial | dosar-lifecycle | US-A-041 |
| [US-113](US-113-tablou-de-bord-kpi-cu-filtrare.md) | Tablou de bord KPI cu filtrare la click | pre-wiki | modified | not-implemented | dosar-lifecycle | US-B-041, US-A-042 |
| [US-114](US-114-cautarea-in-registru.md) | Căutarea în registru | pre-wiki | modified | not-implemented | dosar-lifecycle | US-B-042, US-A-043 |
| [US-115](US-115-gruparea-pe-proiect.md) | Gruparea pe proiect | pre-wiki | modified | not-implemented | dosar-lifecycle | US-B-042, US-A-044 |
| [US-116](US-116-explicarea-starilor-in-context.md) | Explicarea stărilor în context | a-only | unchanged | not-implemented | dosar-lifecycle | US-A-045 |
| [US-117](US-117-retragerea-unui-dosar.md) | Retragerea unui dosar | pre-wiki | modified | not-implemented | dosar-lifecycle | US-B-018, US-B-042, US-A-046 |
| [US-118](US-118-corespondenta-cu-formatul-de-raportare-institutional.md) | Corespondența cu formatul de raportare instituțional | a-only | unchanged | not-implemented | dosar-lifecycle | US-A-047 |
| [US-119](US-119-configurarea-locatiei-de-arhivare.md) | Configurarea locației de arhivare | a-only | unchanged | not-implemented | — | US-A-049 |
| [US-120](US-120-configurarea-canalului-de-notificare.md) | Configurarea canalului de notificare | a-only | unchanged | not-implemented | — | US-A-050 |
| [US-121](US-121-inregistrarea-unei-achizitii.md) | Înregistrarea unei achiziții | stub-only | deferred | unknown | — | US-B-043 |
| [US-122](US-122-intretinerea-registrului-de-achizitii.md) | Întreținerea registrului de achiziții | stub-only | deferred | unknown | — | US-B-044 |
| [US-123](US-123-desemnarea-ofiterilor-de-verificare-a-achizitiilor.md) | Desemnarea ofițerilor de verificare a achizițiilor | stub-only | deferred | unknown | — | US-B-045 |
| [US-124](US-124-preluarea-esantionului-de-achizitii-de-catre.md) | Preluarea eșantionului de achiziții de către coordonator | stub-only | deferred | unknown | — | US-B-046 |
| [US-125](US-125-mentinerea-achizitiei-vizibile-pe-tot-parcursul.md) | Menținerea achiziției vizibile pe tot parcursul | stub-only | deferred | unknown | — | US-B-047 |
| [US-126](US-126-confirmarea-fiecarui-raspuns-in-doi-pasi.md) | Confirmarea fiecărui răspuns în doi pași | stub-only | deferred | unknown | — | US-B-048 |
| [US-127](US-127-etapa-1-declararea-conflictului-de-interese.md) | Etapa 1 — declararea conflictului de interese sau semnarea declarației | stub-only | deferred | unknown | — | US-B-049 |
| [US-128](US-128-etapele-2-3-6-7-consemnarea.md) | Etapele 2, 3, 6, 7 — consemnarea unei justificări obligatorii la răspuns negativ | stub-only | deferred | unknown | — | US-B-050 |
| [US-129](US-129-etapa-2-consemnarea-paginii-din-cererea.md) | Etapa 2 — consemnarea paginii din cererea de finanțare | stub-only | deferred | unknown | — | US-B-051 |
| [US-130](US-130-etapa-4-dirijarea-achizitiilor-peste-prag.md) | Etapa 4 — dirijarea achizițiilor peste prag către verificare manuală | stub-only | deferred | unknown | — | US-B-052 |
| [US-131](US-131-etapa-5-ramificarea-pe-parteneriat-public.md) | Etapa 5 — ramificarea pe parteneriat public vs. privat | stub-only | deferred | unknown | — | US-B-053 |
| [US-132](US-132-etapa-8-verificarea-dublei-finantari.md) | Etapa 8 — verificarea dublei finanțări | stub-only | deferred | unknown | — | US-B-054 |
| [US-133](US-133-etapa-9-generarea-listei-de-verificare.md) | Etapa 9 — generarea listei de verificare și predarea către Ofițer 2 | stub-only | deferred | unknown | — | US-B-055 |
| [US-134](US-134-verificarea-achizitiei-de-catre-ofiter-2.md) | Verificarea achiziției de către Ofițer 2 | stub-only | deferred | unknown | — | US-B-056 |

## Crosswalk surse → elemente (226)

Singura rezoluție supraviețuitoare pentru spațiile de identificatori retrase `US-A-###` / `US-B-###` / `US-C-###` și `UC-A/B/C-###`. 19 surse alimentează mai mult de un element.

### Stratul A — Prototype A (69)

| sursă | element(e) |
|---|---|
| UC-A-001 | UC-007 |
| UC-A-002 | UC-009 |
| UC-A-003 | UC-010, UC-012 |
| UC-A-004 | UC-013 |
| UC-A-005 | UC-014 |
| UC-A-006 | UC-016 |
| UC-A-007 | UC-018 |
| UC-A-008 | UC-005 |
| UC-A-009 | UC-004 |
| UC-A-010 | UC-019 |
| UC-A-011 | UC-001 |
| US-A-001 | US-001 |
| US-A-002 | US-002 |
| US-A-003 | US-004 |
| US-A-004 | US-051 |
| US-A-005 | US-052 |
| US-A-006 | US-053 |
| US-A-007 | US-043 |
| US-A-008 | US-054 |
| US-A-009 | US-055 |
| US-A-010 | US-045 |
| US-A-011 | US-062 |
| US-A-012 | US-063 |
| US-A-013 | US-065 |
| US-A-014 | US-079 |
| US-A-015 | US-064 |
| US-A-016 | US-056 |
| US-A-017 | US-057 |
| US-A-018 | US-025 |
| US-A-019 | US-029 |
| US-A-020 | US-030 |
| US-A-021 | US-032 |
| US-A-022 | US-036 |
| US-A-023 | US-037 |
| US-A-024 | US-038 |
| US-A-025 | US-080 |
| US-A-026 | US-081 |
| US-A-027 | US-035 |
| US-A-028 | US-084 |
| US-A-029 | US-083 |
| US-A-030 | US-092 |
| US-A-031 | US-087, US-088 |
| US-A-032 | US-091 |
| US-A-033 | US-090 |
| US-A-034 | US-097 |
| US-A-035 | US-093 |
| US-A-036 | US-100 |
| US-A-037 | US-102 |
| US-A-038 | US-108 |
| US-A-039 | US-109 |
| US-A-040 | US-110 |
| US-A-041 | US-112 |
| US-A-042 | US-113 |
| US-A-043 | US-114 |
| US-A-044 | US-115 |
| US-A-045 | US-116 |
| US-A-046 | US-117 |
| US-A-047 | US-118 |
| US-A-048 | US-005, US-006 |
| US-A-049 | US-119 |
| US-A-050 | US-120 |
| US-A-051 | US-033 |
| US-A-052 | US-018 |
| US-A-053 | US-019 |
| US-A-054 | US-020 |
| US-A-055 | US-021 |
| US-A-056 | US-022 |
| US-A-057 | US-023 |
| US-A-058 | US-024 |

### Stratul B — Stub (73)

| sursă | element(e) |
|---|---|
| UC-B-001 | UC-007 |
| UC-B-002 | UC-009 |
| UC-B-003 | UC-010, UC-012 |
| UC-B-004 | UC-011 |
| UC-B-005 | UC-013, UC-014 |
| UC-B-006 | UC-016 |
| UC-B-007 | UC-018 |
| UC-B-008 | UC-004, UC-005 |
| UC-B-009 | UC-006 |
| UC-B-010 | UC-020 |
| UC-B-011 | UC-021 |
| UC-B-012 | UC-022 |
| UC-B-013 | UC-002 |
| US-B-001 | US-001 |
| US-B-002 | US-003 |
| US-B-003 | US-002, US-005, US-006 |
| US-B-004 | US-010 |
| US-B-005 | US-011 |
| US-B-006 | US-012 |
| US-B-007 | US-013 |
| US-B-008 | US-025 |
| US-B-009 | US-029 |
| US-B-010 | US-030, US-032 |
| US-B-011 | US-037, US-038 |
| US-B-012 | US-040 |
| US-B-013 | US-039 |
| US-B-014 | US-033 |
| US-B-015 | US-051 |
| US-B-016 | US-043 |
| US-B-017 | US-058 |
| US-B-018 | US-059, US-117 |
| US-B-019 | US-052 |
| US-B-020 | US-062 |
| US-B-021 | US-064 |
| US-B-022 | US-065 |
| US-B-023 | US-066 |
| US-B-024 | US-065 |
| US-B-025 | US-079 |
| US-B-026 | US-069 |
| US-B-027 | US-071, US-072 |
| US-B-028 | US-068 |
| US-B-029 | US-083, US-084 |
| US-B-030 | US-087, US-088, US-091 |
| US-B-031 | US-090 |
| US-B-032 | US-089 |
| US-B-033 | US-094 |
| US-B-034 | US-097 |
| US-B-035 | US-098 |
| US-B-036 | US-095, US-099 |
| US-B-037 | US-102 |
| US-B-038 | US-108 |
| US-B-039 | US-110 |
| US-B-040 | US-111 |
| US-B-041 | US-113 |
| US-B-042 | US-114, US-115, US-117 |
| US-B-043 | US-121 |
| US-B-044 | US-122 |
| US-B-045 | US-123 |
| US-B-046 | US-124 |
| US-B-047 | US-125 |
| US-B-048 | US-126 |
| US-B-049 | US-127 |
| US-B-050 | US-128 |
| US-B-051 | US-129 |
| US-B-052 | US-130 |
| US-B-053 | US-131 |
| US-B-054 | US-132 |
| US-B-055 | US-133 |
| US-B-056 | US-134 |
| US-B-057 | US-104 |
| US-B-058 | US-105 |
| US-B-059 | US-106 |
| US-B-060 | US-107 |

### Stratul C — Wiki (84)

| sursă | element(e) |
|---|---|
| UC-C-001 | UC-007 |
| UC-C-002 | UC-008 |
| UC-C-003 | UC-009 |
| UC-C-004 | UC-010 |
| UC-C-005 | UC-011 |
| UC-C-006 | UC-012 |
| UC-C-007 | UC-013 |
| UC-C-008 | UC-014 |
| UC-C-009 | UC-015 |
| UC-C-010 | UC-016 |
| UC-C-011 | UC-017 |
| UC-C-012 | UC-004 |
| UC-C-013 | UC-005 |
| UC-C-014 | UC-006 |
| UC-C-015 | UC-003 |
| US-C-001 | US-005 |
| US-C-002 | US-006 |
| US-C-003 | US-007, US-021 |
| US-C-004 | US-008 |
| US-C-005 | US-009 |
| US-C-006 | US-025 |
| US-C-007 | US-026 |
| US-C-008 | US-027 |
| US-C-009 | US-028 |
| US-C-010 | US-030 |
| US-C-011 | US-031 |
| US-C-012 | US-033 |
| US-C-013 | US-034 |
| US-C-014 | US-035 |
| US-C-015 | US-036 |
| US-C-016 | US-037 |
| US-C-017 | US-039 |
| US-C-018 | US-040 |
| US-C-019 | US-041, US-051 |
| US-C-020 | US-042, US-052 |
| US-C-021 | US-043 |
| US-C-022 | US-044 |
| US-C-023 | US-045 |
| US-C-024 | US-046 |
| US-C-025 | US-047 |
| US-C-026 | US-048 |
| US-C-027 | US-049 |
| US-C-028 | US-050 |
| US-C-029 | US-060 |
| US-C-030 | US-061 |
| US-C-031 | US-062 |
| US-C-032 | US-065 |
| US-C-033 | US-064 |
| US-C-034 | US-066 |
| US-C-035 | US-067 |
| US-C-036 | US-068 |
| US-C-037 | US-069 |
| US-C-038 | US-070 |
| US-C-039 | US-071 |
| US-C-040 | US-072 |
| US-C-041 | US-073 |
| US-C-042 | US-074 |
| US-C-043 | US-075 |
| US-C-044 | US-076 |
| US-C-045 | US-077 |
| US-C-046 | US-078 |
| US-C-047 | US-079 |
| US-C-048 | US-082 |
| US-C-049 | US-085 |
| US-C-050 | US-083 |
| US-C-051 | US-084 |
| US-C-052 | US-087, US-091 |
| US-C-053 | US-088 |
| US-C-054 | US-086 |
| US-C-055 | US-093 |
| US-C-056 | US-095 |
| US-C-057 | US-096 |
| US-C-058 | US-097 |
| US-C-059 | US-098 |
| US-C-060 | US-099 |
| US-C-061 | US-100 |
| US-C-062 | US-101 |
| US-C-063 | US-102 |
| US-C-064 | US-103 |
| US-C-065 | US-104 |
| US-C-066 | US-014 |
| US-C-067 | US-015 |
| US-C-068 | US-016 |
| US-C-069 | US-017 |

## Totaluri

| coverage | n |
|---|---|
| draft | 76 |
| stub-only | 31 |
| a-only | 24 |
| pre-wiki | 13 |
| team-reviewed | 12 |

| overlay | n |
|---|---|
| new | 64 |
| modified | 45 |
| unchanged | 27 |
| deferred | 18 |
| deprecated | 1 |
| superseded | 1 |

| implementation | n |
|---|---|
| unknown | 84 |
| partial | 34 |
| implemented | 30 |
| not-implemented | 8 |

## `decision: pending` (24)

Descendență exclusiv Prototype A, necoroborată de o sursă cu precedență mai mare.

- [UC-001](UC-001-provizionarea-unui-tenant-nou.md) — Provizionarea unui tenant nou
- [UC-019](UC-019-monitorizarea-portofoliului-de-cereri.md) — Monitorizarea portofoliului de cereri
- [US-004](US-004-incheierea-sesiunii.md) — Încheierea sesiunii
- [US-018](US-018-crearea-si-provizionarea-unui-tenant.md) — Crearea și provizionarea unui tenant
- [US-019](US-019-suspendarea-si-reactivarea-unui-tenant.md) — Suspendarea și reactivarea unui tenant
- [US-020](US-020-administrarea-administratorilor-centrali.md) — Administrarea administratorilor centrali
- [US-022](US-022-vizibilitatea-consolei-limitata-la-metadate-operationale.md) — Vizibilitatea consolei limitată la metadate operaționale
- [US-023](US-023-jurnalul-ciclului-de-viata-al-tenantilor.md) — Jurnalul ciclului de viață al tenanților
- [US-024](US-024-sloguri-valide-si-sloguri-rezervate.md) — Sloguri valide și sloguri rezervate
- [US-053](US-053-indicarea-programului-de-finantare.md) — Indicarea programului de finanțare
- [US-054](US-054-semnalarea-datelor-obligatorii-lipsa.md) — Semnalarea datelor obligatorii lipsă
- [US-055](US-055-constituirea-dosarului.md) — Constituirea dosarului
- [US-056](US-056-impunerea-ordinii-pasilor.md) — Impunerea ordinii pașilor
- [US-057](US-057-reflectarea-rezultatului-verificarii-in-starea-dosarului.md) — Reflectarea rezultatului verificării în starea dosarului
- [US-063](US-063-prezentarea-liniilor-neconforme.md) — Prezentarea liniilor neconforme
- [US-080](US-080-determinarea-populatiei-si-a-dimensiunii-esantionului.md) — Determinarea populației și a dimensiunii eșantionului
- [US-081](US-081-constituirea-fisierului-de-identificare.md) — Constituirea fișierului de identificare
- [US-092](US-092-constituirea-dosarului-electronic-arhivat.md) — Constituirea dosarului electronic arhivat
- [US-109](US-109-consemnarea-constatarii-pe-o-linie-de.md) — Consemnarea constatării pe o linie de eșantion
- [US-112](US-112-registrul-cererilor-cu-starile-lor.md) — Registrul cererilor cu stările lor
- [US-116](US-116-explicarea-starilor-in-context.md) — Explicarea stărilor în context
- [US-118](US-118-corespondenta-cu-formatul-de-raportare-institutional.md) — Corespondența cu formatul de raportare instituțional
- [US-119](US-119-configurarea-locatiei-de-arhivare.md) — Configurarea locației de arhivare
- [US-120](US-120-configurarea-canalului-de-notificare.md) — Configurarea canalului de notificare

## Conflicte (45)

### Rezolvate prin recență (32)

- CF-01 — Vocabularul rolurilor din tenant
- CF-03 — Scopul administrării persoanelor: tenant vs. platformă
- CF-04 — Retragerea unei persoane: ștergere vs. dezactivare
- CF-05 — Mecanismul de stabilire a parolei la primul acces
- CF-07 — Domeniul selectorului de module față de scope-ul v1
- CF-11 — Semantica înlocuirii la importul listei IER: înlocuire per CUI vs. coexistență pe perioade de valabilitate
- CF-12 — Cine stabilește baza IER aplicabilă unei cereri: indicare manuală de către ofițer vs. selecție automată pe data intrării cererii
- CF-14 — Suprascrierea prin investigație externă: verificare 100% sau 75% (clasa 5)
- CF-16 — Obligativitatea celor trei desemnări la salvarea/trimiterea cererii
- CF-17 — Momentul notificării de repartizare și destinatarii ei
- CF-18 — Sursa și momentul datelor de identificare ale cererii: extragere din fișierul de cheltuieli la creare vs. creare manuală cu autocompletare din registrul de risc
- CF-19 — Cine introduce numărul de înregistrare și în ce moment
- CF-20 — Eliminarea unei cereri: ștergere definitivă cu confirmare vs. retragere logică, recuperabilă
- CF-21 — Domeniul observațiilor: orice linie de cheltuială vs. doar liniile problematice
- CF-22 — Traseul verificării preliminare: un singur ofițer vs. circuitul cu doi ofițeri
- CF-23 — Rolul ofițerului 2: triere pe linii cu observații proprii vs. aprobare printr-o singură acțiune
- CF-24 — Cine declanșează generarea notei justificative după verificarea de linia a doua
- CF-26 — Momentul și canalul transmiterii clarificărilor către beneficiar
- CF-27 — Rolul ofițerului 2: triere pe linii cu observații proprii vs. aprobare/respingere
- CF-28 — Actorul care declanșează generarea notei justificative
- CF-29 — Numărul de semnături pe nota justificativă: două vs. trei
- CF-30 — Mecanismul de semnare: atestare în platformă vs. semnare în afara platformei, detectată de platformă
- CF-32 — Momentul emiterii solicitărilor de semnătură: simultan la generare vs. secvențial, după semnătura precedentă
- CF-34 — Natura artefactului de eșantionare: instrucțiune text pentru un instrument extern vs. script IDEA generat de platformă
- CF-36 — Cine creează folderele de lucru și cu ce condiționalitate
- CF-37 — Ce însoțește notificarea de eșantionare: instrucțiune pusă la dispoziție, atașament .iss sau locația scriptului în folderul de lucru
- CF-38 — Exportul istoricului IDEA: parte automată a rulării scriptului vs. acțiune manuală a operatorului
- CF-39 — Cum constată platforma că eșantionarea s-a efectuat: confirmare umană cu verificarea numărului de linii vs. detectare automată a apariției fișierelor
- CF-41 — Destinatarii notificării de eșantion generat
- CF-42 — Numărul și tipurile documentelor de rezultat al verificării eșantionului
- CF-43 — Denumirea și definițiile celor șase indicatori de stadiu
- CF-44 — Amploarea modulului de achiziții în v1

### Nedecidabile (13)

- CF-02 — Constrângerile de validare pe adresa de contact a persoanei
- CF-06 — Arhitectura de acces la fișiere: foldere partajate vs. încărcare în platformă
- CF-08 — Modelul de operare: platformă multi-tenant găzduită vs. instalare la client
- CF-09 — Autoritatea la reimportul fișierului de contracte: suprascriere din Excel vs. păstrarea datelor existente
- CF-10 — Este permisă adăugarea manuală de proiecte/entități în registrul de risc?
- CF-13 — Golurile intervalelor de clasă IER și configurabilitatea lor
- CF-15 — Data cererii: data depunerii extrasă din fișierul de cheltuieli vs. data intrării introdusă manual
- CF-25 — Notificarea ofițerului 1 la respingerea de către ofițerul 2
- CF-31 — Anexa procedurală care guvernează nota justificativă
- CF-33 — Suprafața de consultare a notei înainte de semnare: vizualizator în aplicație vs. deschiderea fișierului din folder
- CF-35 — Proveniența dimensiunilor eșantionului la execuție (conflict de registru #10, Q-B-005)
- CF-40 — Arhitectura accesului la fișiere: eșantionul și fișierele IDEA în platformă vs. pe foldere locale/montate (conflict de registru #11)
- CF-45 — Cărei linii din lista de verificare corespunde Etapa 3 față de Etapa 4
