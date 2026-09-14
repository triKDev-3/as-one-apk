/** Catalogue F-ACH-07 — Demande de produits et matériels sites temporaires. */

export type CatalogSeed = {
  refCode: string;
  name: string;
  category: 'CONSOMMABLE' | 'EQUIPEMENT';
  returnRequired: boolean;
};

export const DEFAULT_MATERIAL_CATALOG: CatalogSeed[] = [
  // Produits et consommables — retour non obligatoire
  { refCode: 'AIR-DES', name: 'AIRWICK', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'AJA', name: 'AJAX', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'ALC', name: 'ALCOOL', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'CAC-NE', name: 'CACHE NEZ', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'CIF-CR', name: 'CIF CREME', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'DET-001', name: 'DETERGENT', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'DIL-001', name: 'DILUANT', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'GAN-LAT-VR', name: 'GANT LATEX VRAC', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'JAV-001', name: 'JAVEL POUDRE', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'LAV-VIT', name: 'LAVE VITRE', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'PRO-G', name: 'PRODUIT OMNIPONT', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'PRO-MOP', name: 'PRODUIT MOP', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'SAC-POU', name: 'SAC POUBELLE', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'TAP-CHA', name: 'TAPI CHAMPOIN', category: 'CONSOMMABLE', returnRequired: false },
  { refCode: 'TAM-PAD', name: 'TAMPON PAD', category: 'CONSOMMABLE', returnRequired: false },

  // Matériels et équipements — retour obligatoire
  { refCode: 'ASP-001', name: 'ASPIRATEUR', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'BAL-CAN', name: 'BALAI CANTONIER', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'BAL-COC', name: 'BALAI COCO', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'BAL-PAL', name: 'BALAI PALMIER', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'BAL-TRA-60', name: 'BALAI TRAPEZE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'BOT-J', name: 'BOTTE JAUNE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'BOT-V', name: 'BOTTE VERTE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'DIS-PAD', name: 'DISQUE PAD', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'ECH-3-3', name: 'ECHAFAUDAGE 3X3M', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'ECH-002', name: 'ECHELLE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'ESC-002', name: 'ESCABEAU', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'FRAN-001', name: 'FRANGES', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'GAN-PVC', name: 'GANT PVC', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'GRA-001', name: 'GRATTOIR', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'INS-SOL', name: 'INSECTICIDE SOLDAT', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'LAM-001', name: 'LAME PAQUET', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'MAN-TEL', name: 'MANCHE TELESCOPIQUE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'MIC-001', name: 'MICROFIBRE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'MON-001', name: 'MONOBROSS', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'MOU-001', name: 'MOUILLEUR', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'PEL-BAL', name: 'PELLE BALAYETTE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'POM-EAU', name: 'POMPE A EAU', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'PUR-WATER', name: 'PURE WATER', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'RAC-TUYAU', name: 'RACCORD TUYAU', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'RAC-VIT', name: 'RACLETTE VITRE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'RAC-SOL', name: 'RACLETTE SOL', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'RAL-001', name: 'RALLONGE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'SEA-003', name: 'SEAU', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'SER-001', name: 'SERPILLERE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'SOU', name: 'SOUFFLEUR', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'TET-LOU', name: 'TETE DE LOUP', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'TUY-TUYAU', name: 'TUYAU', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'ARN-SEC', name: 'HARNAIS DE SECURITE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'CAS-SEC', name: 'CASQUE DE SECURITE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'DIS-MAR', name: 'DISQUE A MARBRE', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'BAC-PRO', name: 'BACHE DE PROTECTION', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'DIS-ABR', name: 'DISQUE ABRASIF P120/220/400', category: 'EQUIPEMENT', returnRequired: true },
  { refCode: 'CROCHET', name: 'CROCHETS', category: 'EQUIPEMENT', returnRequired: true },
];
