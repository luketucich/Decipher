-- CreateTable
CREATE TABLE "Topic" (
    "id" SERIAL NOT NULL,
    "keyword" TEXT NOT NULL,
    "variations" TEXT[],
    "hints" TEXT[],
    "hasBeenUsed" BOOLEAN NOT NULL DEFAULT false,
    "releaseDate" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Topic_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Topic_keyword_key" ON "Topic"("keyword");
