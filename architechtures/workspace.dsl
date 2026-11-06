workspace "Système de tokénisation de téléphone reconditionné" {

    model {
        revendeur = person "Revendeur de téléphone reconditionné"
        proprietaire = person "Propriétaire du téléphone reconditionné"
        systemeTokenisation = softwareSystem "Système de tokénisation de téléphone reconditionné"
        ipfs = softwareSystem "IPFS"

        revendeur -> systemeTokenisation "Établit un lien entre la facture de vente et les informations du téléphone"
        proprietaire -> systemeTokenisation "Déclare son appareil et conserve les informations nécessaires à sa réclamation"
        systemeTokenisation -> ipfs "Échange pour rendre le système décentralisé"
    }

    views {
        systemContext systemeTokenisation "SystemContext" {
            include *
            autoLayout
        }
    }
}
