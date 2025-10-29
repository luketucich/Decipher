-- CreateTable
CREATE TABLE "Topic" (
    "id" TEXT NOT NULL,
    "answer" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "type" TEXT NOT NULL,

    CONSTRAINT "Topic_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Hint" (
    "id" TEXT NOT NULL,
    "topicId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "order" INTEGER NOT NULL,

    CONSTRAINT "Hint_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Topic_date_key" ON "Topic"("date");

-- CreateIndex
CREATE INDEX "Topic_date_idx" ON "Topic"("date");

-- CreateIndex
CREATE INDEX "Hint_topicId_idx" ON "Hint"("topicId");

-- CreateIndex
CREATE UNIQUE INDEX "Hint_topicId_order_key" ON "Hint"("topicId", "order");

-- AddForeignKey
ALTER TABLE "Hint" ADD CONSTRAINT "Hint_topicId_fkey" FOREIGN KEY ("topicId") REFERENCES "Topic"("id") ON DELETE CASCADE ON UPDATE CASCADE;
