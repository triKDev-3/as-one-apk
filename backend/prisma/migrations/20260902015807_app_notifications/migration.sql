-- AlterTable
ALTER TABLE `assignment` ADD COLUMN `fixedSalary` DECIMAL(10, 2) NULL,
    ADD COLUMN `missionType` VARCHAR(191) NULL DEFAULT 'TEMPORAIRE',
    ADD COLUMN `routineDays` JSON NULL;

-- AlterTable
ALTER TABLE `pointage` MODIFY `type` ENUM('ARRIVEE', 'DEPART', 'PRESENCE_PERMANENCE', 'ABSENT') NOT NULL;

-- CreateTable
CREATE TABLE `IncidentPenalty` (
    `id` VARCHAR(191) NOT NULL,
    `incidentId` VARCHAR(191) NOT NULL,
    `agentId` VARCHAR(191) NULL,
    `target` ENUM('ONE_AGENT', 'WHOLE_GROUP') NOT NULL,
    `amount` DECIMAL(10, 2) NOT NULL,
    `reason` VARCHAR(191) NULL,
    `appliedById` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `IncidentPenalty_agentId_createdAt_idx`(`agentId`, `createdAt`),
    INDEX `IncidentPenalty_incidentId_idx`(`incidentId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `AppNotification` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `title` VARCHAR(191) NOT NULL,
    `body` VARCHAR(191) NOT NULL,
    `type` VARCHAR(191) NOT NULL,
    `data` JSON NULL,
    `readAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `AppNotification_userId_createdAt_idx`(`userId`, `createdAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `IncidentPenalty` ADD CONSTRAINT `IncidentPenalty_incidentId_fkey` FOREIGN KEY (`incidentId`) REFERENCES `Incident`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `IncidentPenalty` ADD CONSTRAINT `IncidentPenalty_agentId_fkey` FOREIGN KEY (`agentId`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `IncidentPenalty` ADD CONSTRAINT `IncidentPenalty_appliedById_fkey` FOREIGN KEY (`appliedById`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AppNotification` ADD CONSTRAINT `AppNotification_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
