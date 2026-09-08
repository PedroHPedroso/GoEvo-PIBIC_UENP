CREATE TABLE IF NOT EXISTS jogadores (
  id UUID PRIMARY KEY,
  submission_id UUID NOT NULL UNIQUE,
  nome VARCHAR(50) NOT NULL,
  idade SMALLINT NOT NULL CHECK (idade BETWEEN 1 AND 100),
  instituicao VARCHAR(100) NOT NULL,
  nivel VARCHAR(20) NOT NULL CHECK (
    nivel IN ('fundamental1', 'fundamental2', 'medio', 'superior', 'outros')
  ),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (CHAR_LENGTH(BTRIM(nome)) BETWEEN 2 AND 50),
  CHECK (CHAR_LENGTH(BTRIM(instituicao)) BETWEEN 3 AND 100)
);

-- Aplicar também em bancos existentes. NULL = fase ainda não registrada; unidade: ms.
ALTER TABLE jogadores
  ADD COLUMN IF NOT EXISTS tempo_fase_1_ms BIGINT CHECK (tempo_fase_1_ms >= 0),
  ADD COLUMN IF NOT EXISTS tempo_fase_2_ms BIGINT CHECK (tempo_fase_2_ms >= 0),
  ADD COLUMN IF NOT EXISTS tempo_fase_3_ms BIGINT CHECK (tempo_fase_3_ms >= 0),
  ADD COLUMN IF NOT EXISTS tempo_fase_4_ms BIGINT CHECK (tempo_fase_4_ms >= 0);
