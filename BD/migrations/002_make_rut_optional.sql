-- Migración: Hacer el trigger de validación de RUT opcional
-- Si el RUT es NULL, no validar

CREATE OR REPLACE FUNCTION applicants_validate_rut()
RETURNS TRIGGER AS $$
DECLARE dv_expected TEXT;
BEGIN
  -- Si no hay RUT, permitir (RUT opcional)
  IF NEW.rut_number IS NULL AND NEW.rut_dv IS NULL THEN
    RETURN NEW;
  END IF;

  -- Si solo uno está NULL, es error
  IF NEW.rut_number IS NULL OR NEW.rut_dv IS NULL THEN
    RAISE EXCEPTION 'RUT incompleto: tanto rut_number como rut_dv deben estar presentes o ambos NULL';
  END IF;

  -- Validar RUT
  NEW.rut_dv := UPPER(TRIM(NEW.rut_dv));
  dv_expected := rut_calc_dv(NEW.rut_number);
  IF dv_expected IS NULL OR NEW.rut_dv <> dv_expected THEN
    RAISE EXCEPTION 'RUT inválido: %-% (dígito verificador esperado: %)',
      NEW.rut_number, NEW.rut_dv, dv_expected;
  END IF;

  RETURN NEW;
END $$ LANGUAGE plpgsql;
