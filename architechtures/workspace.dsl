workspace "Système de tokénisation de téléphone reconditionné" "Modèle C4 aligné sur constitutions/mission.md : contexte, conteneurs et vues dynamiques (CU2, CU3)." {

    model {

        // ---------------------------------------------------------------
        // Personnes
        // ---------------------------------------------------------------
        revendeur = person "Revendeur de téléphone reconditionné" "Établit le lien entre la facture de vente et les informations du téléphone, et signe l'attestation d'origine à chaque vente." {
            properties {
                "Point ouvert" "Revendeurs agréés : qui autorise un revendeur à émettre des jetons ? (mission.md §9)"
            }
            tags "Point ouvert"
        }
        proprietaire = person "Propriétaire du téléphone reconditionné" "Déclare son appareil, détient le jeton et la clé de ses données, et prouve sa légitimité."
        acquereur = person "Acquéreur d'occasion" "Vérifie le statut d'un téléphone avant achat et reçoit le jeton lors de la cession."
        forcesOrdre = person "Forces de l'ordre / PLCC" "Reçoivent les éléments de traçage d'un appareil déclaré volé." {
            properties {
                "Point ouvert" "Déclaration de vol : validation (dépôt de plainte, PLCC) avant d'afficher le statut « volé » ? (mission.md §9)"
            }
            tags "Point ouvert"
        }

        // ---------------------------------------------------------------
        // Systèmes externes
        // ---------------------------------------------------------------
        ipfs = softwareSystem "IPFS" "Stocke les attestations chiffrées, adressées par leur contenu (CID)." {
            tags "Système externe"
        }
        blockchainPublique = softwareSystem "Blockchain publique" "Registre des jetons : unicité, propriété et transferts. Chaque jeton référence le CID IPFS de l'attestation chiffrée." {
            properties {
                "Point ouvert" "Choix de la blockchain : réseau public, frais de transaction, qui les paie ? (mission.md §9)"
            }
            tags "Système externe" "Point ouvert"
        }

        // ---------------------------------------------------------------
        // Système étudié et ses conteneurs
        // ---------------------------------------------------------------
        systemeTokenisation = softwareSystem "Système de tokénisation de téléphone reconditionné" "Émet les jetons, gère les attestations et le registre de statut des appareils." {

            appRevendeur = container "Application revendeur" "Utilisée par le revendeur pour émettre l'attestation d'achat signée et le jeton lors d'une vente." "À définir" {
                tags "Proposition"
            }
            appProprietaire = container "Application / portefeuille propriétaire" "Détient la clé du portefeuille du jeton et la clé de chiffrement des données ; signe les défis, divulgue sélectivement les champs de l'attestation, transfère le jeton, déclare le vol." "À définir" {
                tags "Proposition"
            }
            apiBackend = container "API backend" "Interface serveur du système utilisée par les applications. Le périmètre exact de ses responsabilités reste à définir. Elle ne peut jamais déchiffrer seule les attestations." "À définir" {
                tags "Proposition"
            }
            serviceConsultation = container "Service de consultation IMEI" "Calcule HMAC(pepper, IMEI), interroge le registre et ne renvoie que le statut (non tokénisé, actif, volé). Point de centralisation assumé (arbitrage n°1) : limitation de débit, journal d'audit, rotation du pepper." "À définir" {
                properties {
                    "Point ouvert" "Accès au service : public et anonyme avec limitation, ou réservé aux comptes vérifiés ? (mission.md §9)"
                }
                tags "Proposition" "Point ouvert"
            }
            hsm = container "HSM / coffre-fort de clés" "Stocke le pepper utilisé pour calculer le HMAC de l'IMEI. Le pepper ne permet aucun déchiffrement." "À définir (HSM ou coffre-fort de clés)" {
                tags "Proposition" "Stockage"
            }
            smartContracts = container "Smart contracts du registre de jetons" "Code du projet déployé sur la blockchain publique : unicité, propriété, transferts et statut des jetons." "À définir" {
                tags "Proposition"
            }
            baseIndex = container "Base d'index" "Index du registre par HMAC(pepper, IMEI). Rôle exact vis-à-vis du registre porté par la blockchain à confirmer." "À définir" {
                tags "Proposition" "Stockage"
            }
        }

        // ---------------------------------------------------------------
        // Relations — niveau contexte
        // ---------------------------------------------------------------
        revendeur -> systemeTokenisation "Établit un lien entre la facture de vente et les informations du téléphone, et signe l'attestation d'origine"
        proprietaire -> systemeTokenisation "Déclare son appareil et conserve les informations nécessaires à sa réclamation"
        acquereur -> systemeTokenisation "Consulte le statut d'un téléphone via son IMEI et reçoit le jeton lors de la cession"
        systemeTokenisation -> forcesOrdre "Fournit, à l'initiative du propriétaire, les éléments de traçage d'un appareil déclaré volé (divulgation sélective)"
        systemeTokenisation -> ipfs "Stocke les attestations chiffrées"
        systemeTokenisation -> blockchainPublique "Émet et transfère les jetons"
        forcesOrdre -> blockchainPublique "Identifie le revendeur émetteur désigné par le jeton, lorsque l'enquête se fait sans le propriétaire"
        forcesOrdre -> revendeur "Requiert les informations de l'attestation par la voie judiciaire normale, lorsque l'enquête se fait sans le propriétaire"

        // ---------------------------------------------------------------
        // Relations — niveau conteneurs
        // ---------------------------------------------------------------
        revendeur -> appRevendeur "Utilise pour signer l'attestation d'origine"
        proprietaire -> appProprietaire "Utilise pour prouver sa légitimité, céder le téléphone et déclarer un vol"
        acquereur -> appProprietaire "Reçoit le jeton"
        acquereur -> serviceConsultation "Saisit l'IMEI pour consulter le statut"

        appRevendeur -> apiBackend "Soumet l'attestation signée"
        appRevendeur -> smartContracts "Émet le jeton"
        appProprietaire -> smartContracts "Transfère le jeton et met à jour son statut"
        appProprietaire -> apiBackend "Dépose et récupère les attestations chiffrées"
        appProprietaire -> forcesOrdre "Transmet par divulgation sélective les éléments de traçage (IMEI, numéro de série, modèle, revendeur)"

        apiBackend -> ipfs "Stocke les attestations chiffrées"
        apiBackend -> baseIndex "Alimente l'index"
        serviceConsultation -> hsm "Utilise le pepper pour calculer le HMAC de l'IMEI"
        serviceConsultation -> baseIndex "Recherche le jeton par HMAC"
        serviceConsultation -> smartContracts "Lit le statut du jeton"
        smartContracts -> blockchainPublique "Est déployé sur"
    }

    views {

        systemContext systemeTokenisation "SystemContext" "Vue contexte du système de tokénisation." {
            include *
            autoLayout
        }

        container systemeTokenisation "Conteneurs" "Conteneurs proposés du système de tokénisation. Les technologies sont à définir (piletechnologique.md est vide)." {
            include *
            autoLayout
        }

        dynamic systemeTokenisation "CU2_Cession" "CU2 — Céder un téléphone sans facture." {
            acquereur -> serviceConsultation "1. Saisit l'IMEI du téléphone"
            serviceConsultation -> hsm "2. Calcule HMAC(pepper, IMEI)"
            serviceConsultation -> baseIndex "3. Recherche le jeton par HMAC"
            serviceConsultation -> smartContracts "4. Lit le statut du jeton"
            proprietaire -> appProprietaire "5. Prouve sa possession en signant un défi aléatoire (CU1)"
            appProprietaire -> smartContracts "6. Transfère le jeton à l'acquéreur"
            smartContracts -> blockchainPublique "7. Enregistre le transfert"
            acquereur -> appProprietaire "8. Reçoit le jeton et hérite de l'historique"
            autoLayout
        }

        dynamic systemeTokenisation "CU3_DeclarationVol" "CU3 — Déclarer un vol, avec le propriétaire." {
            proprietaire -> appProprietaire "1. Déclare le vol"
            appProprietaire -> smartContracts "2. Passe le statut du jeton à « volé »"
            smartContracts -> blockchainPublique "3. Enregistre le statut"
            acquereur -> serviceConsultation "4. Consulte le statut via l'IMEI"
            serviceConsultation -> smartContracts "5. Lit le statut « volé »"
            appProprietaire -> forcesOrdre "6. Transmet IMEI, numéro de série, modèle et revendeur par divulgation sélective"
            autoLayout
        }

        dynamic systemeTokenisation "CU3_SansProprietaire" "CU3 — Enquête sans le propriétaire : passage par le revendeur émetteur." {
            forcesOrdre -> blockchainPublique "1. Identifie le revendeur émetteur désigné par le jeton"
            forcesOrdre -> revendeur "2. Requiert les informations par la voie judiciaire normale"
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Stockage" {
                shape Cylinder
            }
            element "Système externe" {
                background #999999
                color #ffffff
            }
            element "Point ouvert" {
                stroke #d9822b
                strokeWidth 5
            }
            element "Proposition" {
                border dashed
            }
        }
    }
}
