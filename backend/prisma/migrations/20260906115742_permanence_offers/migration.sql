-- CreateTable
CREATE TABLE `PermanenceSchedule` (
    `id` VARCHAR(191) NOT NULL,
    `siteId` VARCHAR(191) NOT NULL,
    `createdById` VARCHAR(191) NOT NULL,
    `title` VARCHAR(191) NULL,
    `workDaysPerWeek` INTEGER NOT NULL DEFAULT 6,
    `status` ENUM('DRAFT', 'PUBLISHED', 'CLOSED') NOT NULL DEFAULT 'DRAFT',
    `publishedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `PermanenceSchedule_siteId_status_idx`(`siteId`, `status`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PermanenceSlot` (
    `id` VARCHAR(191) NOT NULL,
    `scheduleId` VARCHAR(191) NOT NULL,
    `label` VARCHAR(191) NULL,
    `startTime` VARCHAR(191) NOT NULL,
    `endTime` VARCHAR(191) NOT NULL,
    `salary` DECIMAL(12, 2) NOT NULL,
    `requiredAgents` INTEGER NOT NULL DEFAULT 1,

    INDEX `PermanenceSlot_scheduleId_idx`(`scheduleId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PermanenceApplication` (
    `id` VARCHAR(191) NOT NULL,
    `slotId` VARCHAR(191) NOT NULL,
    `agentId` VARCHAR(191) NOT NULL,
    `status` ENUM('PENDING', 'ACCEPTED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
    `rejectMessage` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `resolvedAt` DATETIME(3) NULL,

    INDEX `PermanenceApplication_agentId_status_idx`(`agentId`, `status`),
    UNIQUE INDEX `PermanenceApplication_slotId_agentId_key`(`slotId`, `agentId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `PermanenceSchedule` ADD CONSTRAINT `PermanenceSchedule_siteId_fkey` FOREIGN KEY (`siteId`) REFERENCES `Site`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PermanenceSlot` ADD CONSTRAINT `PermanenceSlot_scheduleId_fkey` FOREIGN KEY (`scheduleId`) REFERENCES `PermanenceSchedule`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PermanenceApplication` ADD CONSTRAINT `PermanenceApplication_slotId_fkey` FOREIGN KEY (`slotId`) REFERENCES `PermanenceSlot`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PermanenceApplication` ADD CONSTRAINT `PermanenceApplication_agentId_fkey` FOREIGN KEY (`agentId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
