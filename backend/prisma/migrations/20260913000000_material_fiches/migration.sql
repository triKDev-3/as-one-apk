-- Catalogue + fiches F-ACH-07
ALTER TABLE `MaterialItem` ADD COLUMN `refCode` VARCHAR(191) NULL;
ALTER TABLE `MaterialItem` ADD COLUMN `returnRequired` BOOLEAN NOT NULL DEFAULT false;
CREATE UNIQUE INDEX `MaterialItem_refCode_key` ON `MaterialItem`(`refCode`);

CREATE TABLE `MaterialFiche` (
  `id` VARCHAR(191) NOT NULL,
  `code` VARCHAR(191) NOT NULL,
  `siteId` VARCHAR(191) NOT NULL,
  `status` VARCHAR(191) NOT NULL DEFAULT 'REQUESTED',
  `requestDate` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `plannedReturn` DATETIME(3) NULL,
  `deliveredAt` DATETIME(3) NULL,
  `closedAt` DATETIME(3) NULL,
  `sector` VARCHAR(191) NULL,
  `spaceCount` INTEGER NULL,
  `personCount` INTEGER NULL,
  `dayCount` INTEGER NULL,
  `requesterId` VARCHAR(191) NULL,
  `magasinierId` VARCHAR(191) NULL,
  `notes` VARCHAR(191) NULL,
  `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` DATETIME(3) NOT NULL,
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE UNIQUE INDEX `MaterialFiche_code_key` ON `MaterialFiche`(`code`);
CREATE INDEX `MaterialFiche_siteId_status_idx` ON `MaterialFiche`(`siteId`, `status`);

CREATE TABLE `MaterialFicheLine` (
  `id` VARCHAR(191) NOT NULL,
  `ficheId` VARCHAR(191) NOT NULL,
  `itemId` VARCHAR(191) NOT NULL,
  `qtyRequested` INTEGER NOT NULL DEFAULT 0,
  `qtyDelivered` INTEGER NOT NULL DEFAULT 0,
  `qtyReturned` INTEGER NOT NULL DEFAULT 0,
  `outNotes` VARCHAR(191) NULL,
  `returnNotes` VARCHAR(191) NULL,
  `returnState` ENUM('BON', 'DEGRADE', 'MANQUANT') NULL,
  `isLost` BOOLEAN NOT NULL DEFAULT false,
  `isChecked` BOOLEAN NOT NULL DEFAULT false,
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE UNIQUE INDEX `MaterialFicheLine_ficheId_itemId_key` ON `MaterialFicheLine`(`ficheId`, `itemId`);

ALTER TABLE `MaterialRetention` ADD COLUMN `ficheLineId` VARCHAR(191) NULL;
ALTER TABLE `MaterialRetention` ADD COLUMN `reason` VARCHAR(191) NULL;
ALTER TABLE `MaterialRetention` ADD COLUMN `appliedById` VARCHAR(191) NULL;
ALTER TABLE `MaterialRetention` MODIFY `movementId` VARCHAR(191) NULL;
ALTER TABLE `MaterialRetention` ALTER `isApplied` SET DEFAULT false;
CREATE UNIQUE INDEX `MaterialRetention_ficheLineId_key` ON `MaterialRetention`(`ficheLineId`);

ALTER TABLE `MaterialFiche` ADD CONSTRAINT `MaterialFiche_siteId_fkey` FOREIGN KEY (`siteId`) REFERENCES `Site`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `MaterialFiche` ADD CONSTRAINT `MaterialFiche_requesterId_fkey` FOREIGN KEY (`requesterId`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `MaterialFiche` ADD CONSTRAINT `MaterialFiche_magasinierId_fkey` FOREIGN KEY (`magasinierId`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE `MaterialFicheLine` ADD CONSTRAINT `MaterialFicheLine_ficheId_fkey` FOREIGN KEY (`ficheId`) REFERENCES `MaterialFiche`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `MaterialFicheLine` ADD CONSTRAINT `MaterialFicheLine_itemId_fkey` FOREIGN KEY (`itemId`) REFERENCES `MaterialItem`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE `MaterialRetention` ADD CONSTRAINT `MaterialRetention_ficheLineId_fkey` FOREIGN KEY (`ficheLineId`) REFERENCES `MaterialFicheLine`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
