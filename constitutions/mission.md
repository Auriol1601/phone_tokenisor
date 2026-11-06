# Mission — Système de tokénisation de téléphone reconditionné

> Document fondateur. Il découle du diagramme de contexte C4
> ([architechtures/workspace.dsl](../architechtures/workspace.dsl)) et doit évoluer avec lui.

## 1. Raison d'être

Donner à chaque téléphone reconditionné une **identité numérique vérifiable**, qui relie
l'appareil à sa facture de vente et à ses propriétaires successifs.

Le jeton **remplace la facture papier**. Il suit le téléphone de main en main et permet
à son détenteur de **prouver sa légitimité sans tout révéler**.

## 2. Problème adressé

- Sur le marché du reconditionné, la preuve d'origine et de propriété d'un appareil repose
  sur des documents dispersés (facture papier ou PDF, numéros de série, IMEI).
- Ces preuves se perdent, se falsifient, ou restent chez un seul acteur (le revendeur).
- Un téléphone cédé de particulier à particulier arrive souvent **sans facture**.
- En cas de vol, la victime peine à fournir aux forces de l'ordre (police, PLCC) les
  éléments nécessaires au traçage de l'appareil.

## 3. Acteurs (contexte C4)

| Acteur | Type | Rôle dans le système |
|---|---|---|
| **Revendeur de téléphone reconditionné** | Personne | Établit le lien entre la facture de vente et les informations du téléphone, et signe l'attestation d'origine. |
| **Propriétaire du téléphone reconditionné** | Personne | Déclare son appareil, détient le jeton et la clé de ses données, et prouve sa légitimité. |
| **Acquéreur d'occasion** *(à ajouter au diagramme)* | Personne | Vérifie un téléphone avant achat et reçoit le jeton lors de la cession. |
| **Forces de l'ordre / PLCC** *(à ajouter au diagramme)* | Personne / organisation | Reçoivent les éléments de traçage d'un appareil déclaré volé. |
| **Système de tokénisation** | Système (périmètre du projet) | Émet les jetons, gère les attestations et le registre de statut des appareils. |
| **IPFS** | Système externe | Stocke les attestations chiffrées, adressées par leur contenu. |
| **Blockchain publique** *(à ajouter au diagramme)* | Système externe | Registre des jetons : unicité, propriété, transferts. |

## 4. Mission

1. **Tokéniser** : à chaque vente, le revendeur émet un jeton qui associe de façon
   infalsifiable le téléphone et une attestation d'achat qu'il signe.
2. **Rendre la preuve au propriétaire** : seul le propriétaire détient la clé de ses
   données et choisit ce qu'il révèle.
3. **Assurer la traçabilité de main en main** : lors d'une cession, le jeton est transféré
   et l'historique (origine, transferts) suit le téléphone.
4. **Permettre de vérifier qu'un téléphone n'est pas volé** avant un achat.
5. **Coopérer avec les forces de l'ordre** : fournir, à l'initiative de la victime, les
   éléments clés du traçage.
6. **Décentraliser** : les preuves survivent à la disparition d'un acteur, y compris de
   l'éditeur du système.

## 5. Cas d'usage fondateurs

### CU1 — Prouver sa légitimité
Le propriétaire signe un défi aléatoire avec la clé du portefeuille qui détient le jeton.
Il prouve ainsi la possession sans rien révéler d'autre. S'il le faut, il révèle des champs
choisis de l'attestation (modèle, date, revendeur) par divulgation sélective. Les autres
champs (prix, identité) restent cachés.

### CU2 — Céder un téléphone sans facture
1. L'acquéreur consulte le statut du téléphone via son IMEI (voir l'arbitrage n°1).
2. Le vendeur prouve qu'il détient le jeton (CU1).
3. Le jeton est transféré sur la blockchain. L'acquéreur hérite de l'historique.
4. Un vendeur incapable de transférer le jeton est un **signal d'alerte**.

### CU3 — Déclarer un vol et coopérer avec la police / PLCC
1. Le propriétaire déclare le vol. Le statut « volé » devient visible lors de toute
   consultation (CU2).
2. Il transmet aux forces de l'ordre, par divulgation sélective, les éléments de traçage :
   IMEI, numéro de série, modèle, revendeur d'origine.
3. Si l'enquête se fait sans le propriétaire, la blockchain désigne le **revendeur émetteur**.
   Celui-ci est légalement tenu de conserver ses factures, et la réquisition passe par lui,
   par la voie judiciaire normale. **Le système ne détient aucune clé de déchiffrement.**

## 6. Arbitrages structurants

### ⭐ Arbitrage n°1 — Recherche de statut par IMEI : index à clé secrète (DÉCIDÉ)

**Le problème.** Vérifier qu'un téléphone n'est pas volé (CU2, CU3) exige de pouvoir le
retrouver par son IMEI. Or l'IMEI ne peut pas être publié, même haché :
- il compte 15 chiffres, dont les 8 premiers (TAC) identifient le modèle et sont publics,
  et le dernier est un chiffre de contrôle ;
- il ne reste donc qu'environ 10⁶ combinaisons par modèle, et un `hash(IMEI)` publié se
  retrouve par force brute en quelques secondes.

**La décision.** Le registre est indexé par un **HMAC de l'IMEI** calculé avec une clé
secrète (le *pepper*) détenue par un **service de consultation** du système.

| Ce qui est publié (blockchain / IPFS) | Ce qui reste secret |
|---|---|
| `HMAC(pepper, IMEI)` → identifiant du jeton | Le pepper (stocké en HSM ou coffre-fort de clés) |
| Statut du jeton : actif, volé, perdu | L'IMEI en clair |
| CID IPFS de l'attestation chiffrée | Le contenu de l'attestation |

**Fonctionnement.**
- L'acquéreur saisit l'IMEI. Le service calcule le HMAC, interroge le registre et ne
  renvoie que le **statut** : non tokénisé, actif, ou déclaré volé.
- Le service ne renvoie jamais l'identité du propriétaire ni le contenu de l'attestation.

**Le prix accepté.** Ce service est un **point de centralisation assumé**, limité à la
seule fonction de recherche. Mesures de compensation :
- **limitation de débit** et authentification légère, pour empêcher l'énumération des IMEI ;
- le pepper ne permet **pas** de déchiffrer les données : il sert seulement à l'index ;
- **journal d'audit** des consultations ;
- plan de **rotation du pepper** et de reconstruction de l'index ;
- si le service tombe, les jetons, les transferts et les preuves de possession (CU1)
  restent fonctionnels. Seule la recherche par IMEI devient indisponible.

**Option écartée.** Pas d'index du tout (vérification uniquement à partir du jeton présenté
par le vendeur) : cela protège mieux la vie privée, mais rend impossible la détection d'un
téléphone volé dont le vendeur ne présente aucun jeton, ce qui contredit la mission 4.

### Arbitrage n°2 — Détention des clés de chiffrement (orientation)
- La clé des données appartient au **propriétaire**. Le système ne peut jamais déchiffrer
  seul.
- Le **revendeur émetteur** garde un accès en lecture à l'attestation qu'il a émise
  (chiffrement multi-destinataires).
- La **perte de clé** est couverte par une récupération qui ne dépend pas uniquement du
  système, par exemple un partage de secret 2 sur 3.
- À la cession, l'ancien propriétaire rechiffre les données pour le nouveau.

### Arbitrage n°3 — Rôle de la blockchain (orientation)
IPFS garantit l'**intégrité** des données, mais ni la **propriété** ni l'**unicité**.
Une blockchain publique, externe au système, porte les jetons (de type NFT). Chaque jeton
référence le CID IPFS de l'attestation chiffrée.

## 7. Principes directeurs

- **Vérifiabilité** : toute attestation est signée par son émetteur et vérifiable par un tiers.
- **Divulgation minimale** : chaque vérification révèle le strict nécessaire.
- **Décentralisation par défaut, centralisation explicite** : toute centralisation est un
  arbitrage documenté, limité et compensé (voir l'arbitrage n°1).
- **Protection des données personnelles** : aucune donnée personnelle ni IMEI en clair sur
  IPFS ou la blockchain.
- **Simplicité pour les acteurs** : la cryptographie est invisible pour l'utilisateur.

## 8. Périmètre

**Dans le périmètre**
- Émission du jeton et de l'attestation signée par le revendeur.
- Preuve de possession et divulgation sélective (CU1).
- Cession et transfert du jeton (CU2).
- Déclaration de vol et service de consultation de statut par IMEI (CU3, arbitrage n°1).

**Hors périmètre (pour l'instant)**
- Traitement des réclamations SAV.
- Place de marché ou paiement.
- Preuves à divulgation nulle de connaissance avancées (ZK), par exemple « acheté il y a
  moins de 12 mois » : prévues pour une phase ultérieure.

## 9. Questions ouvertes

- **Revendeurs agréés** : qui autorise un revendeur à émettre des jetons ?
- **Déclaration de vol** : faut-il une validation (dépôt de plainte, PLCC) avant d'afficher
  le statut « volé », pour éviter les déclarations abusives ?
- **Choix de la blockchain** : réseau public, frais de transaction, qui les paie ?
- **Accès au service de consultation** : public et anonyme avec limitation, ou réservé
  aux comptes vérifiés ?
- **Cadre légal** : obligations locales sur la conservation des données et la coopération
  avec la PLCC.
